--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local DataService = require(script.Parent.DataService)

local ShopService = {}

-- Use the pre-built catalog from Constants
local SHOP_CATALOG = Constants.SHOP_CATALOG

-- Result codes for client feedback
local RESULT_CODES = {
	SUCCESS = "SUCCESS",
	INVALID_PARAMS = "INVALID_PARAMS",
	ITEM_NOT_FOUND = "ITEM_NOT_FOUND",
	INSUFFICIENT_FUNDS = "INSUFFICIENT_FUNDS",
	ALREADY_OWNED = "ALREADY_OWNED",
	TRANSACTION_FAILED = "TRANSACTION_FAILED",
	INVALID_TYPE = "INVALID_TYPE",
}

function ShopService:Init()
	print("[ShopService] Initializing...")
	
	-- Main purchase function that routes to specific handlers
	local purchaseItemFunc = Remotes.GetFunction("PurchaseItem")
	purchaseItemFunc.OnServerInvoke = function(player, itemId)
		return self:PurchaseItem(player, itemId)
	end
	
	-- Create purchase result event for UI feedback
	Remotes.GetEvent("PurchaseResult")
end

function ShopService:Start()
	print("[ShopService] Starting...")
end

-- Main purchase router with pcall protection
function ShopService:PurchaseItem(player, itemId)
	if not player or not itemId then
		self:LogTransaction(player, itemId, false, RESULT_CODES.INVALID_PARAMS)
		return false, RESULT_CODES.INVALID_PARAMS
	end
	
	local itemDef = SHOP_CATALOG[itemId]
	if not itemDef then
		self:LogTransaction(player, itemId, false, RESULT_CODES.ITEM_NOT_FOUND)
		return false, RESULT_CODES.ITEM_NOT_FOUND
	end
	
	-- Route to specific purchase handler based on type
	local success, result
	local itemType = itemDef.type
	
	if itemType == "stat" then
		success, result = self:PurchaseStatUpgrade(player, itemDef)
	elseif itemType == "weapon" then
		success, result = self:PurchaseWeapon(player, itemDef)
	elseif itemType == "consumable" then
		success, result = self:PurchaseConsumable(player, itemDef)
	elseif itemType == "cosmetic" then
		success, result = self:PurchaseCosmetic(player, itemDef)
	else
		self:LogTransaction(player, itemId, false, RESULT_CODES.INVALID_TYPE)
		return false, RESULT_CODES.INVALID_TYPE
	end
	
	-- Send result to client
	local purchaseResultEvent = Remotes.GetEvent("PurchaseResult")
	purchaseResultEvent:FireClient(player, success, result, itemDef.name, itemDef.cost)
	
	return success, result
end

-- Purchase stat upgrades with rollback protection
function ShopService:PurchaseStatUpgrade(player, itemDef)
	local cost = itemDef.cost
	local previousGold = DataService.GetGold(player)
	
	-- Check balance FIRST
	if previousGold < cost then
		self:LogTransaction(player, itemDef.id, false, RESULT_CODES.INSUFFICIENT_FUNDS)
		return false, RESULT_CODES.INSUFFICIENT_FUNDS
	end
	
	-- Wrap transaction in pcall
	local success, err = pcall(function()
		-- Deduct gold
		local deducted = DataService.RemoveGold(player, cost)
		if not deducted then
			error("Failed to deduct gold")
		end
		
		-- Apply stat upgrade
		local upgraded = DataService.ApplyStatUpgrade(player, itemDef.stat, itemDef.value)
		if not upgraded then
			error("Failed to apply stat upgrade")
		end
	end)
	
	if not success then
		-- Rollback: restore gold
		DataService.SetGold(player, previousGold)
		self:LogTransaction(player, itemDef.id, false, RESULT_CODES.TRANSACTION_FAILED, nil, err)
		return false, RESULT_CODES.TRANSACTION_FAILED
	end
	
	self:LogTransaction(player, itemDef.id, true, RESULT_CODES.SUCCESS, cost)
	return true, RESULT_CODES.SUCCESS
end

-- Purchase weapons with rollback protection
function ShopService:PurchaseWeapon(player, itemDef)
	local cost = itemDef.cost
	local previousGold = DataService.GetGold(player)
	
	-- Check balance FIRST
	if previousGold < cost then
		self:LogTransaction(player, itemDef.id, false, RESULT_CODES.INSUFFICIENT_FUNDS)
		return false, RESULT_CODES.INSUFFICIENT_FUNDS
	end
	
	-- Wrap transaction in pcall
	local success, err = pcall(function()
		-- Deduct gold
		local deducted = DataService.RemoveGold(player, cost)
		if not deducted then
			error("Failed to deduct gold")
		end
		
		-- Add weapon to inventory
		local added = DataService.AddWeapon(player, itemDef)
		if not added then
			error("Failed to add weapon")
		end
	end)
	
	if not success then
		-- Rollback: restore gold
		DataService.SetGold(player, previousGold)
		self:LogTransaction(player, itemDef.id, false, RESULT_CODES.TRANSACTION_FAILED, nil, err)
		return false, RESULT_CODES.TRANSACTION_FAILED
	end
	
	self:LogTransaction(player, itemDef.id, true, RESULT_CODES.SUCCESS, cost)
	return true, RESULT_CODES.SUCCESS
end

-- Purchase consumables with rollback protection
function ShopService:PurchaseConsumable(player, itemDef)
	local cost = itemDef.cost
	local previousGold = DataService.GetGold(player)
	
	-- Check balance FIRST
	if previousGold < cost then
		self:LogTransaction(player, itemDef.id, false, RESULT_CODES.INSUFFICIENT_FUNDS)
		return false, RESULT_CODES.INSUFFICIENT_FUNDS
	end
	
	-- Wrap transaction in pcall
	local success, err = pcall(function()
		-- Deduct gold
		local deducted = DataService.RemoveGold(player, cost)
		if not deducted then
			error("Failed to deduct gold")
		end
		
		-- Add consumable to inventory (stacks)
		local added = DataService.AddConsumable(player, itemDef)
		if not added then
			error("Failed to add consumable")
		end
	end)
	
	if not success then
		-- Rollback: restore gold
		DataService.SetGold(player, previousGold)
		self:LogTransaction(player, itemDef.id, false, RESULT_CODES.TRANSACTION_FAILED, nil, err)
		return false, RESULT_CODES.TRANSACTION_FAILED
	end
	
	self:LogTransaction(player, itemDef.id, true, RESULT_CODES.SUCCESS, cost)
	return true, RESULT_CODES.SUCCESS
end

-- Purchase cosmetics with rollback protection (unique items)
function ShopService:PurchaseCosmetic(player, itemDef)
	local cost = itemDef.cost
	local previousGold = DataService.GetGold(player)
	
	-- Check if already owned
	if DataService.OwnsCosmetic(player, itemDef.id) then
		self:LogTransaction(player, itemDef.id, false, RESULT_CODES.ALREADY_OWNED)
		return false, RESULT_CODES.ALREADY_OWNED
	end
	
	-- Check balance FIRST
	if previousGold < cost then
		self:LogTransaction(player, itemDef.id, false, RESULT_CODES.INSUFFICIENT_FUNDS)
		return false, RESULT_CODES.INSUFFICIENT_FUNDS
	end
	
	-- Wrap transaction in pcall
	local success, err = pcall(function()
		-- Deduct gold
		local deducted = DataService.RemoveGold(player, cost)
		if not deducted then
			error("Failed to deduct gold")
		end
		
		-- Add cosmetic to inventory
		local added, reason = DataService.AddCosmetic(player, itemDef)
		if not added then
			error("Failed to add cosmetic: " .. tostring(reason))
		end
	end)
	
	if not success then
		-- Rollback: restore gold
		DataService.SetGold(player, previousGold)
		self:LogTransaction(player, itemDef.id, false, RESULT_CODES.TRANSACTION_FAILED, nil, err)
		return false, RESULT_CODES.TRANSACTION_FAILED
	end
	
	self:LogTransaction(player, itemDef.id, true, RESULT_CODES.SUCCESS, cost)
	return true, RESULT_CODES.SUCCESS
end

function ShopService:LogTransaction(player, itemId, success, reason, amount, errorMsg)
	local playerName = player and player.Name or "Unknown"
	local playerId = player and player.UserId or 0
	local status = success and "SUCCESS" or "FAILED"
	
	local logMsg = string.format("[ShopService] Transaction %s | Player: %s (%d) | Item: %s | Amount: %s | Reason: %s",
		status,
		playerName,
		playerId,
		tostring(itemId),
		tostring(amount or "N/A"),
		reason
	)
	
	if errorMsg then
		logMsg = logMsg .. " | Error: " .. tostring(errorMsg)
	end
	
	print(logMsg)
end

function ShopService:GetShopItems()
	return Constants.SHOP_ITEMS
end

return ShopService
