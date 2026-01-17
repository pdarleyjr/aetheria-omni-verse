--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local DataService = require(script.Parent.DataService)

local ShopService = {}

-- Build lookup table from Constants.SHOP_ITEMS
local SHOP_CATALOG = {}
for _, item in ipairs(Constants.SHOP_ITEMS) do
	SHOP_CATALOG[item.id] = item
end

function ShopService:Init()
	print("[ShopService] Initializing...")
	
	local purchaseItemFunc = Remotes.GetFunction("PurchaseItem")
	
	purchaseItemFunc.OnServerInvoke = function(player, itemId)
		return self:PurchaseItem(player, itemId)
	end
end

function ShopService:Start()
	print("[ShopService] Starting...")
end

function ShopService:PurchaseItem(player, itemId)
	-- Validation
	if not player or not itemId then
		self:LogTransaction(player, itemId, false, "Invalid parameters")
		return false, "Invalid parameters"
	end
	
	local itemDef = SHOP_CATALOG[itemId]
	if not itemDef then
		self:LogTransaction(player, itemId, false, "Item not found")
		return false, "Item not found"
	end
	
	local price = itemDef.price
	local currentGold = DataService.GetGold(player)
	
	-- Check if player has enough gold
	if currentGold < price then
		self:LogTransaction(player, itemId, false, "Insufficient Gold")
		return false, "Not enough Gold (need " .. price .. ", have " .. currentGold .. ")"
	end
	
	-- Deduct Gold
	local deducted = DataService.RemoveGold(player, price)
	if not deducted then
		self:LogTransaction(player, itemId, false, "Failed to deduct Gold")
		return false, "Transaction failed"
	end
	
	-- Grant item to inventory
	local success, uniqueId = DataService.AddItem(player, itemDef)
	if not success then
		-- Refund Gold if item grant failed
		DataService.AddGold(player, price)
		self:LogTransaction(player, itemId, false, "Failed to grant item")
		return false, "Failed to add item to inventory"
	end
	
	self:LogTransaction(player, itemId, true, "Success", price)
	return true, "Purchased " .. itemDef.name
end

function ShopService:LogTransaction(player, itemId, success, reason, amount)
	local playerName = player and player.Name or "Unknown"
	local playerId = player and player.UserId or 0
	local status = success and "SUCCESS" or "FAILED"
	
	print(string.format("[ShopService] Transaction %s | Player: %s (%d) | Item: %s | Amount: %s | Reason: %s",
		status,
		playerName,
		playerId,
		tostring(itemId),
		tostring(amount or "N/A"),
		reason
	))
end

function ShopService:GetShopItems()
	return Constants.SHOP_ITEMS
end

return ShopService
