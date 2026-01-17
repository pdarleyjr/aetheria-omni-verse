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
		Gold = 0,
	},
	Stats = {
		Level = 1,
		EXP = 0,
		PlayTime = 0,
	},
	Inventory = {
		Spirits = {},
		Items = {},
		Escrow = { -- Items currently in active trade
			Spirits = {},
			Items = {}
		}
	}, 
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
			
			-- Restore any items stuck in Escrow from previous session (crash recovery)
			local data = profile.Data
			if data.Inventory.Escrow then
				for category, items in pairs(data.Inventory.Escrow) do
					if not data.Inventory[category] then data.Inventory[category] = {} end
					for itemId, item in pairs(items) do
						data.Inventory[category][itemId] = item
						items[itemId] = nil
						print("[DataService] Restored item from Escrow:", itemId)
					end
				end
			end
			
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

function DataService.GetGold(player: Player)
	local data = DataService.GetData(player)
	if data and data.Currencies then
		return data.Currencies.Gold or 0
	end
	return 0
end

function DataService.AddGold(player: Player, amount: number)
	local result = DataService.AddCurrency(player, "Gold", amount)
	if result then
		local GoldUpdate = Remotes.GetEvent("GoldUpdate")
		GoldUpdate:FireClient(player, DataService.GetGold(player))
	end
	return result
end

function DataService.RemoveGold(player: Player, amount: number)
	local result = DataService.RemoveCurrency(player, "Gold", amount)
	if result then
		local GoldUpdate = Remotes.GetEvent("GoldUpdate")
		GoldUpdate:FireClient(player, DataService.GetGold(player))
	end
	return result
end

function DataService.AddItem(player: Player, itemData)
	local data = DataService.GetData(player)
	if not data then return false end
	
	if not data.Inventory.Items then
		data.Inventory.Items = {}
	end
	
	local uniqueId = itemData.id .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
	data.Inventory.Items[uniqueId] = {
		id = itemData.id,
		name = itemData.name,
		type = itemData.type,
		stats = itemData.stats,
		effect = itemData.effect,
		value = itemData.value,
		acquiredAt = os.time()
	}
	
	DataService.UpdateClientHUD(player)
	return true, uniqueId
end

function DataService.MoveToEscrow(player: Player, category: string, itemId: string)
	local data = DataService.GetData(player)
	if not data then return false end
	
	local inventory = data.Inventory
	if not inventory[category] then return false end
	
	local item = inventory[category][itemId]
	if not item then return false end
	
	-- Check if equipped (specific to Spirits)
	if category == "Spirits" and inventory.EquippedSpirit == itemId then
		return false -- Cannot trade equipped spirit
	end
	
	-- Initialize Escrow category if missing
	if not inventory.Escrow then inventory.Escrow = { Spirits = {}, Items = {} } end
	if not inventory.Escrow[category] then inventory.Escrow[category] = {} end
	
	-- Move item
	inventory.Escrow[category][itemId] = item
	inventory[category][itemId] = nil
	
	DataService.UpdateClientHUD(player)
	return true
end

function DataService.RestoreFromEscrow(player: Player, category: string, itemId: string)
	local data = DataService.GetData(player)
	if not data then return false end
	
	local inventory = data.Inventory
	if not inventory.Escrow or not inventory.Escrow[category] then return false end
	
	local item = inventory.Escrow[category][itemId]
	if not item then return false end
	
	-- Move back
	inventory[category][itemId] = item
	inventory.Escrow[category][itemId] = nil
	
	DataService.UpdateClientHUD(player)
	return true
end

function DataService.ExecuteTrade(playerA: Player, playerB: Player, offerA: any, offerB: any)
	local dataA = DataService.GetData(playerA)
	local dataB = DataService.GetData(playerB)
	
	if not dataA or not dataB then return false end
	
	-- Verify all items are still in Escrow
	for category, items in pairs(offerA) do
		for itemId, _ in pairs(items) do
			if not dataA.Inventory.Escrow[category][itemId] then return false end
		end
	end
	for category, items in pairs(offerB) do
		for itemId, _ in pairs(items) do
			if not dataB.Inventory.Escrow[category][itemId] then return false end
		end
	end
	
	-- Execute Swap
	-- Move A's items to B
	for category, items in pairs(offerA) do
		for itemId, _ in pairs(items) do
			local itemData = dataA.Inventory.Escrow[category][itemId]
			dataA.Inventory.Escrow[category][itemId] = nil
			
			-- Add to B
			if not dataB.Inventory[category] then dataB.Inventory[category] = {} end
			dataB.Inventory[category][itemId] = itemData
		end
	end
	
	-- Move B's items to A
	for category, items in pairs(offerB) do
		for itemId, _ in pairs(items) do
			local itemData = dataB.Inventory.Escrow[category][itemId]
			dataB.Inventory.Escrow[category][itemId] = nil
			
			-- Add to A
			if not dataA.Inventory[category] then dataA.Inventory[category] = {} end
			dataA.Inventory[category][itemId] = itemData
		end
	end
	
	DataService.UpdateClientHUD(playerA)
	DataService.UpdateClientHUD(playerB)
	return true
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
