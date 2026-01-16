--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local UpdateHUDEvent = Remotes.GetEvent("UpdateHUD")

-- Assume ProfileService is in Shared/Modules based on previous step
-- In a real scenario, it might be in ServerScriptService, but we placed the mock in Shared.
local ProfileService = require(ReplicatedStorage.Shared.Modules.ProfileService)

local DataService = {}

-- // SCHEMA DEFINITION //
local PROFILE_TEMPLATE = {
	Currencies = {
		Essence = 0,
		Aether = 0,
		Crystals = 0,
	},
	Stats = {
		Level = 1,
		EXP = 0,
		PlayTime = 0,
	},
	Inventory = {}, -- Empty table
}

local ProfileStore = ProfileService.GetProfileStore("PlayerData_Test_001", PROFILE_TEMPLATE)

local Profiles = {} -- [player] = profile

-- // PRIVATE FUNCTIONS //

local function PlayerAdded(player: Player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	
	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing data from template
		
		profile:ListenToRelease(function()
			Profiles[player] = nil
			-- The profile could've been loaded on another Roblox server:
			player:Kick("Profile released - Session Lock")
		end)
		
		if player:IsDescendantOf(Players) then
			Profiles[player] = profile
			print("[DataService] Profile loaded for " .. player.Name)
			DataService.UpdateClientHUD(player)
		else
			-- Player left before the profile loaded:
			profile:Release()
		end
	else
		-- The profile could've been loaded on another Roblox server:
		player:Kick("Profile load fail - Please rejoin") 
	end
end

local function PlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile then
		profile:Release()
	end
end

-- // PUBLIC API //

function DataService.GetData(player: Player)
	local profile = Profiles[player]
	if profile then
		return profile.Data
	end
	return nil
end

function DataService.UpdateClientHUD(player: Player)
	local data = DataService.GetData(player)
	if data then
		UpdateHUDEvent:FireClient(player, data)
	end
end

function DataService.AddCurrency(player: Player, currency: string, amount: number)
	local data = DataService.GetData(player)
	if data and data.Currencies and data.Currencies[currency] ~= nil then
		data.Currencies[currency] = data.Currencies[currency] + amount
		DataService.UpdateClientHUD(player)
		return true
	end
	return false
end

function DataService.RemoveCurrency(player: Player, currency: string, amount: number)
	local data = DataService.GetData(player)
	if data and data.Currencies and data.Currencies[currency] ~= nil then
		if data.Currencies[currency] >= amount then
			data.Currencies[currency] = data.Currencies[currency] - amount
			DataService.UpdateClientHUD(player)
			return true
		end
	end
	return false
end

function DataService.AddEssence(player: Player, amount: number)
	return DataService.AddCurrency(player, "Essence", amount)
end

-- // INITIALIZATION //

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

-- // GLOBAL ACCESS //
_G.GetData = DataService.GetData
_G.UpdateHUD = DataService.UpdateClientHUD

return DataService
