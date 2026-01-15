--!strict
--[[
	RealmService.lua
	Manages player Realms (floating islands), including creation, teleportation,
	furniture placement, and passive income generation.
	
	Features:
	- Realm instance creation and management
	- Visitor tracking and buffs
	- Furniture placement with validation
	- Passive income calculation and distribution
	- Realm party events
]]

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Only run on server
if not RunService:IsServer() then
	error("RealmService can only be required on the server")
end

-- Services
local DataService = require(ServerScriptService.Server.Services.DataService)
local PlayerService = require(ServerScriptService.Server.Services.PlayerService)

-- Types
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

type RealmInstance = {
	Owner: Player,
	Model: Model,
	SpawnPoint: CFrame,
	Visitors: { Player },
}

-- Constants
local PASSIVE_INCOME_RATE = 10 -- Essence per minute per realm level
local MAX_REALM_SIZE = 200 -- Maximum studs from center
local MIN_ITEM_SPACING = 5 -- Minimum distance between items
local INCOME_UPDATE_INTERVAL = 60 -- Update income every 60 seconds

-- Service
local RealmService = {
	_realmInstances = {} :: { [number]: RealmInstance }, -- UserId -> RealmInstance
	_activeParties = {} :: { [number]: boolean }, -- UserId -> is party active
}

-- Calculate passive income based on realm data
local function calculatePassiveIncome(realmData: RealmData, timeDelta: number): number
	local incomePerSecond = (PASSIVE_INCOME_RATE * realmData.Level) / 60
	return math.floor(incomePerSecond * timeDelta)
end

-- Validate furniture placement position
local function validatePlacement(realmData: RealmData, position: Vector3, itemId: string): boolean
	-- Check if within realm bounds
	local distance = position.Magnitude
	if distance > MAX_REALM_SIZE then
		return false
	end
	
	-- Check spacing from other items
	for _, placedItem in realmData.PlacedItems do
		local otherPos = placedItem.Position
		local spacing = (position - otherPos).Magnitude
		if spacing < MIN_ITEM_SPACING then
			return false
		end
	end
	
	return true
end

-- Create a physical realm instance in the world
local function createRealmModel(owner: Player, realmData: RealmData): Model
	local realmModel = Instance.new("Model")
	realmModel.Name = `{owner.Name}'s Realm`
	
	-- Create base island platform
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = Vector3.new(100, 5, 100)
	platform.Position = Vector3.new(0, 0, 0)
	platform.Anchored = true
	platform.Material = Enum.Material.Grass
	platform.BrickColor = BrickColor.new("Bright green")
	platform.Parent = realmModel
	
	-- Create spawn point
	local spawnPoint = Instance.new("SpawnLocation")
	spawnPoint.Name = "SpawnLocation"
	spawnPoint.Size = Vector3.new(6, 1, 6)
	spawnPoint.Position = Vector3.new(0, 10, 0)
	spawnPoint.Anchored = true
	spawnPoint.Transparency = 0.5
	spawnPoint.CanCollide = false
	spawnPoint.Parent = realmModel
	
	-- Place existing furniture from data
	for itemId, itemData in realmData.PlacedItems do
		-- In production, this would load actual furniture models
		-- For now, create placeholder cubes
		local furniture = Instance.new("Part")
		furniture.Name = itemId
		furniture.Size = Vector3.new(4, 4, 4)
		furniture.Position = itemData.Position
		furniture.Orientation = itemData.Rotation
		furniture.Anchored = true
		furniture.Material = Enum.Material.Plastic
		furniture.BrickColor = BrickColor.new("Bright blue")
		furniture.Parent = realmModel
	end
	
	return realmModel
end

-- Get or create realm instance for player
function RealmService:GetRealmInstance(player: Player): RealmInstance?
	local userId = player.UserId
	local instance = self._realmInstances[userId]
	
	if instance then
		return instance
	end
	
	-- Create new instance
	local data = DataService:GetPlayerData(player)
	if not data then
		return nil
	end
	
	local realmModel = createRealmModel(player, data.Realm)
	realmModel.Parent = workspace
	
	instance = {
		Owner = player,
		Model = realmModel,
		SpawnPoint = CFrame.new(0, 10, 0),
		Visitors = {},
	}
	
	self._realmInstances[userId] = instance
	print(`Created realm instance for {player.Name}`)
	
	return instance
end

-- Teleport player to a realm
function RealmService:TeleportToRealm(visitor: Player, ownerId: number): boolean
	local ownerInstance = self._realmInstances[ownerId]
	if not ownerInstance then
		-- Try to find owner
		local owner = nil
		for _, player in game:GetService("Players"):GetPlayers() do
			if player.UserId == ownerId then
				owner = player
				break
			end
		end
		
		if owner then
			ownerInstance = self:GetRealmInstance(owner)
		end
	end
	
	if not ownerInstance then
		warn(`Realm not found for owner ID {ownerId}`)
		return false
	end
	
	-- Teleport visitor
	PlayerService:TeleportToPosition(visitor, ownerInstance.SpawnPoint)
	
	-- Track visitor
	table.insert(ownerInstance.Visitors, visitor)
	
	-- Increment visitor count in data
	local ownerData = DataService:GetPlayerData(ownerInstance.Owner)
	if ownerData then
		ownerData.Realm.Visitors += 1
	end
	
	print(`Teleported {visitor.Name} to {ownerInstance.Owner.Name}'s realm`)
	return true
end

-- Place furniture in realm
function RealmService:PlaceFurniture(player: Player, itemId: string, position: Vector3, rotation: Vector3): boolean
	local data = DataService:GetPlayerData(player)
	if not data then
		return false
	end
	
	-- Validate placement
	if not validatePlacement(data.Realm, position, itemId) then
		warn(`Invalid furniture placement for {player.Name}`)
		return false
	end
	
	-- Check if player owns item in inventory
	-- (Simplified - in production, check inventory and consume item)
	
	-- Add to realm data
	local placedItemData: PlacedItemData = {
		ItemId = itemId,
		Position = position,
		Rotation = rotation,
	}
	
	local placementId = `{itemId}_{os.time()}`
	data.Realm.PlacedItems[placementId] = placedItemData
	
	-- Update physical realm if instance exists
	local instance = self._realmInstances[player.UserId]
	if instance then
		local furniture = Instance.new("Part")
		furniture.Name = placementId
		furniture.Size = Vector3.new(4, 4, 4)
		furniture.Position = position
		furniture.Orientation = rotation
		furniture.Anchored = true
		furniture.Material = Enum.Material.Plastic
		furniture.BrickColor = BrickColor.new("Bright blue")
		furniture.Parent = instance.Model
	end
	
	print(`Placed furniture {itemId} in {player.Name}'s realm`)
	return true
end

-- Remove furniture from realm
function RealmService:RemoveFurniture(player: Player, placementId: string): boolean
	local data = DataService:GetPlayerData(player)
	if not data then
		return false
	end
	
	if not data.Realm.PlacedItems[placementId] then
		return false
	end
	
	-- Remove from data
	data.Realm.PlacedItems[placementId] = nil
	
	-- Update physical realm
	local instance = self._realmInstances[player.UserId]
	if instance then
		local furniture = instance.Model:FindFirstChild(placementId)
		if furniture then
			furniture:Destroy()
		end
	end
	
	print(`Removed furniture {placementId} from {player.Name}'s realm`)
	return true
end

-- Start realm party (buffs for all visitors)
function RealmService:StartRealmParty(player: Player): boolean
	local userId = player.UserId
	
	if self._activeParties[userId] then
		return false -- Party already active
	end
	
	local instance = self:GetRealmInstance(player)
	if not instance then
		return false
	end
	
	self._activeParties[userId] = true
	print(`Started realm party for {player.Name}`)
	
	-- Party lasts for 10 minutes
	task.delay(600, function()
		self._activeParties[userId] = nil
		print(`Realm party ended for {player.Name}`)
	end)
	
	return true
end

-- Calculate and award passive income
function RealmService:UpdatePassiveIncome(player: Player): ()
	local data = DataService:GetPlayerData(player)
	if not data then
		return
	end
	
	local currentTime = os.time()
	local timeDelta = currentTime - data.Realm.LastIncomeTime
	
	if timeDelta < 1 then
		return -- Too soon
	end
	
	local income = calculatePassiveIncome(data.Realm, timeDelta)
	
	if income > 0 then
		data.Realm.PassiveIncomeAccumulated += income
		data.Realm.LastIncomeTime = currentTime
		
		-- Award the income
		DataService:IncrementCurrency(player, "Essence", income)
		print(`Awarded {income} passive income to {player.Name}`)
	end
end

-- Cleanup realm instance
local function cleanupRealmInstance(userId: number): ()
	local instance = RealmService._realmInstances[userId]
	if instance then
		instance.Model:Destroy()
		RealmService._realmInstances[userId] = nil
	end
end

-- Passive income update loop
local function passiveIncomeLoop(): ()
	while true do
		task.wait(INCOME_UPDATE_INTERVAL)
		
		for _, player in game:GetService("Players"):GetPlayers() do
			RealmService:UpdatePassiveIncome(player)
		end
	end
end

-- Initialize service
function RealmService:Init(): ()
	print("Initializing RealmService...")
	print("RealmService initialized")
end

-- Start service
function RealmService:Start(): ()
	print("Starting RealmService...")
	
	-- Start passive income loop
	task.spawn(passiveIncomeLoop)
	
	-- Cleanup on player leave
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		cleanupRealmInstance(player.UserId)
	end)
	
	print("RealmService started")
end

return RealmService
