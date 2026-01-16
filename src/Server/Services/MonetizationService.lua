local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local DataService = require(ServerScriptService.Server.Services.DataService)

local MonetizationService = {}

function MonetizationService:Init()
	print("[MonetizationService] Initializing...")
end

function MonetizationService:Start()
	print("[MonetizationService] Starting...")
	
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:ProcessReceipt(receiptInfo)
	end
end

function MonetizationService:ProcessReceipt(receiptInfo)
	local playerId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	
	local player = Players:GetPlayerByUserId(playerId)
	if not player then
		-- Player not in game, return NotProcessed to retry later
		return Enum.ProductPurchaseDecision.NotProcessed
	end
	
	local success, result = pcall(function()
		return self:HandlePurchase(player, productId)
	end)
	
	if success and result then
		print("[MonetizationService] Purchase successful for " .. player.Name)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn("[MonetizationService] Purchase failed: " .. tostring(result))
		return Enum.ProductPurchaseDecision.NotProcessed
	end
end

function MonetizationService:HandlePurchase(player, productId)
	local data = DataService.GetData(player)
	if not data then return false end
	
	if productId == Constants.PRODUCTS.SpiritKeys then
		-- Award Spirit Keys (Consumable)
		local amount = 5 -- Example amount
		local itemId = "SpiritKey"
		
		if not data.Inventory.Items[itemId] then
			data.Inventory.Items[itemId] = { Id = itemId, Amount = 0, Name = "Spirit Key", Type = "Consumable" }
		end
		
		local item = data.Inventory.Items[itemId]
		item.Amount = (item.Amount or 0) + amount
		
		DataService.UpdateClientHUD(player)
		return true
		
	elseif productId == Constants.PRODUCTS.BlueprintPack then
		-- Award Blueprint Pack (Bundle)
		local blueprints = {"Blueprint_A", "Blueprint_B"} -- Example items
		
		for _, bpId in ipairs(blueprints) do
			if not data.Inventory.Items[bpId] then
				data.Inventory.Items[bpId] = { Id = bpId, Amount = 0, Name = bpId, Type = "Blueprint" }
			end
			local item = data.Inventory.Items[bpId]
			item.Amount = (item.Amount or 0) + 1
		end
		
		DataService.UpdateClientHUD(player)
		return true
	end
	
	return false
end

function MonetizationService:HasAutoLoot(player)
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Constants.GAMEPASSES.OmniPass)
	end)
	
	if success then
		return hasPass
	end
	return false
end

function MonetizationService:GetMaxSpiritEquips(player)
	local baseEquips = 3
	local hasPass = self:HasAutoLoot(player) -- Re-use the check
	
	if hasPass then
		return baseEquips + 2
	end
	return baseEquips
end

return MonetizationService
