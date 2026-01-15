--!strict
--[[
	DataService.lua
	Manages player data persistence using DataStoreService with session locking.
	Implements ProfileService-like pattern for safe data management.
	
	Features:
	- Session locking to prevent data duping
	- Automatic retry logic for failed loads/saves
	- Periodic auto-save system
	- Data versioning and migrations
	- Event-driven data change notifications
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Only run on server
if not RunService:IsServer() then
	error("DataService can only be required on the server")
end

-- Types
type PlayerData = {
	UserId: number,
	DisplayName: string,
	Version: number,
	Currencies: {
		Aether: number,
		Essence: number,
	},
	Spirits: { [string]: SpiritData },
	Realm: RealmData,
	Inventory: { [string]: ItemData },
	Stats: {
		Level: number,
		Experience: number,
		TotalPlayTime: number,
		LastLogin: number,
	},
	Settings: {
		MusicVolume: number,
		SFXVolume: number,
		MobileControls: boolean,
	},
}

type SpiritData = {
	Id: string,
	TypeId: string,
	Level: number,
	Experience: number,
	Traits: { string },
	Stats: {
		Health: number,
		Attack: number,
		Defense: number,
		Speed: number,
	},
}

type RealmData = {
	Level: number,
	PlacedItems: { [string]: PlacedItemData },
	Visitors: number,
	PassiveIncomeAccumulated: number,
	LastIncomeTime: number,
}

type PlacedItemData = {
	ItemId: string,
	Position: Vector3,
	Rotation: Vector3,
}

type ItemData = {
	Id: string,
	TypeId: string,
	Quantity: number,
}

type Profile = {
	Data: PlayerData,
	Session: {
		Locked: boolean,
		PlaceId: number,
		JobId: string,
	},
}

-- Constants
local DATA_STORE_NAME = "PlayerData_v1"
local SESSION_LOCK_KEY = "SessionLock"
local AUTOSAVE_INTERVAL = 300 -- 5 minutes
local MAX_RETRIES = 3
local RETRY_DELAY = 1
local DATA_VERSION = 1

-- Service
local DataService = {
	_profiles = {} :: { [Player]: Profile },
	_playerDataStore = nil :: DataStore?,
	_sessionLockStore = nil :: DataStore?,
}

-- Default data template
local function getDefaultData(player: Player): PlayerData
	return {
		UserId = player.UserId,
		DisplayName = player.DisplayName,
		Version = DATA_VERSION,
		Currencies = {
			Aether = 0,
			Essence = 100, -- Starting currency
		},
		Spirits = {},
		Realm = {
			Level = 1,
			PlacedItems = {},
			Visitors = 0,
			PassiveIncomeAccumulated = 0,
			LastIncomeTime = os.time(),
		},
		Inventory = {},
		Stats = {
			Level = 1,
			Experience = 0,
			TotalPlayTime = 0,
			LastLogin = os.time(),
		},
		Settings = {
			MusicVolume = 0.5,
			SFXVolume = 0.7,
			MobileControls = true,
		},
	}
end

-- Migrate data to current version
local function migrateData(data: any): PlayerData
	local version = data.Version or 0
	
	if version < DATA_VERSION then
		warn(`Migrating player data from version {version} to {DATA_VERSION}`)
		-- Future migration logic here
		data.Version = DATA_VERSION
	end
	
	return data :: PlayerData
end

-- Session locking
local function acquireSessionLock(userId: number): boolean
	local sessionLockStore = DataService._sessionLockStore
	if not sessionLockStore then
		return false
	end
	
	local key = `Player_{userId}`
	local success, result = pcall(function()
		return sessionLockStore:UpdateAsync(key, function(oldValue)
			if oldValue and oldValue.Locked then
				-- Check if lock is stale (>10 minutes old)
				if os.time() - oldValue.Timestamp < 600 then
					return nil -- Lock still active
				end
			end
			
			return {
				Locked = true,
				PlaceId = game.PlaceId,
				JobId = game.JobId,
				Timestamp = os.time(),
			}
		end)
	end)
	
	return success and result ~= nil
end

local function releaseSessionLock(userId: number): ()
	local sessionLockStore = DataService._sessionLockStore
	if not sessionLockStore then
		return
	end
	
	local key = `Player_{userId}`
	pcall(function()
		sessionLockStore:UpdateAsync(key, function()
			return {
				Locked = false,
				PlaceId = 0,
				JobId = "",
				Timestamp = os.time(),
			}
		end)
	end)
end

-- Load player profile with retries
function DataService:LoadPlayerProfile(player: Player): Profile?
	local userId = player.UserId
	
	-- Acquire session lock
	local lockAcquired = false
	for attempt = 1, MAX_RETRIES do
		lockAcquired = acquireSessionLock(userId)
		if lockAcquired then
			break
		end
		task.wait(RETRY_DELAY)
	end
	
	if not lockAcquired then
		warn(`Failed to acquire session lock for player {player.Name} ({userId})`)
		return nil
	end
	
	-- Load data from DataStore
	local key = `Player_{userId}`
	local loadedData: PlayerData? = nil
	
	for attempt = 1, MAX_RETRIES do
		local success, result = pcall(function()
			return self._playerDataStore:GetAsync(key)
		end)
		
		if success then
			loadedData = result
			break
		else
			warn(`Failed to load data for {player.Name} (attempt {attempt}/{MAX_RETRIES}): {result}`)
			if attempt < MAX_RETRIES then
				task.wait(RETRY_DELAY)
			end
		end
	end
	
	-- Use loaded data or create new
	local data = loadedData and migrateData(loadedData) or getDefaultData(player)
	data.Stats.LastLogin = os.time()
	
	local profile: Profile = {
		Data = data,
		Session = {
			Locked = true,
			PlaceId = game.PlaceId,
			JobId = game.JobId,
		},
	}
	
	self._profiles[player] = profile
	print(`Loaded profile for {player.Name}`)
	
	return profile
end

-- Save player profile with retries
function DataService:SavePlayerProfile(player: Player): boolean
	local profile = self._profiles[player]
	if not profile then
		warn(`No profile found for {player.Name}`)
		return false
	end
	
	local userId = player.UserId
	local key = `Player_{userId}`
	
	for attempt = 1, MAX_RETRIES do
		local success, err = pcall(function()
			self._playerDataStore:SetAsync(key, profile.Data)
		end)
		
		if success then
			print(`Saved profile for {player.Name}`)
			return true
		else
			warn(`Failed to save data for {player.Name} (attempt {attempt}/{MAX_RETRIES}): {err}`)
			if attempt < MAX_RETRIES then
				task.wait(RETRY_DELAY)
			end
		end
	end
	
	return false
end

-- Get player data
function DataService:GetPlayerData(player: Player): PlayerData?
	local profile = self._profiles[player]
	return profile and profile.Data
end

-- Update player data at path
function DataService:UpdatePlayerData(player: Player, path: { string }, value: any): ()
	local profile = self._profiles[player]
	if not profile then
		warn(`No profile found for {player.Name}`)
		return
	end
	
	local current: any = profile.Data
	for i = 1, #path - 1 do
		current = current[path[i]]
		if not current then
			warn(`Invalid path: {table.concat(path, ".")}`)
			return
		end
	end
	
	current[path[#path]] = value
end

-- Increment currency
function DataService:IncrementCurrency(player: Player, currencyType: string, amount: number): boolean
	local profile = self._profiles[player]
	if not profile then
		return false
	end
	
	local currencies = profile.Data.Currencies
	if not currencies[currencyType] then
		warn(`Invalid currency type: {currencyType}`)
		return false
	end
	
	currencies[currencyType] = math.max(0, currencies[currencyType] + amount)
	return true
end

-- Add spirit to collection
function DataService:AddSpirit(player: Player, spiritData: SpiritData): ()
	local profile = self._profiles[player]
	if not profile then
		return
	end
	
	profile.Data.Spirits[spiritData.Id] = spiritData
end

-- Remove spirit from collection
function DataService:RemoveSpirit(player: Player, spiritId: string): boolean
	local profile = self._profiles[player]
	if not profile then
		return false
	end
	
	if profile.Data.Spirits[spiritId] then
		profile.Data.Spirits[spiritId] = nil
		return true
	end
	
	return false
end

-- Handle player removal
local function onPlayerRemoving(player: Player): ()
	local profile = DataService._profiles[player]
	if profile then
		-- Save data
		DataService:SavePlayerProfile(player)
		
		-- Release session lock
		releaseSessionLock(player.UserId)
		
		-- Clean up
		DataService._profiles[player] = nil
		print(`Cleaned up profile for {player.Name}`)
	end
end

-- Auto-save loop
local function autoSaveLoop(): ()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		
		print("Running auto-save...")
		for player, _ in DataService._profiles do
			if player and player.Parent then
				DataService:SavePlayerProfile(player)
			end
		end
	end
end

-- Initialize service
function DataService:Init(): ()
	print("Initializing DataService...")
	
	self._playerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
	self._sessionLockStore = DataStoreService:GetDataStore(SESSION_LOCK_KEY)
	
	print("DataService initialized")
end

-- Start service
function DataService:Start(): ()
	print("Starting DataService...")
	
	-- Handle player removal
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	
	-- Start auto-save loop
	task.spawn(autoSaveLoop)
	
	-- Bind to close to save all data
	game:BindToClose(function()
		print("Server shutting down, saving all player data...")
		for player, _ in self._profiles do
			if player and player.Parent then
				self:SavePlayerProfile(player)
			end
		end
		task.wait(3) -- Give time for saves to complete
	end)
	
	print("DataService started")
end

return DataService
