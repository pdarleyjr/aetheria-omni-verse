--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local ShopService = {}

local ITEMS = {
	["Basic Sword"] = {
		Cost = 50,
		Currency = "Essence",
		Type = "Weapon",
		Damage = 15
	}
}

function ShopService:Init()
	print("[ShopService] Initializing...")
	
	-- Ensure the RemoteFunction exists
	local buyItemFunc = Remotes.GetFunction("BuyItem")
	
	buyItemFunc.OnServerInvoke = function(player, itemId)
		return self:BuyItem(player, itemId)
	end
end

function ShopService:Start()
	print("[ShopService] Starting...")
end

function ShopService:BuyItem(player, itemId)
	local itemDef = ITEMS[itemId]
	if not itemDef then return false, "Item not found" end
	
	local cost = itemDef.Cost
	local currency = itemDef.Currency
	
	if DataService.RemoveCurrency(player, currency, cost) then
		-- Give Item
		local data = DataService.GetData(player)
		if data then
			if not data.Inventory.Items then data.Inventory.Items = {} end
			
			-- Generate unique ID or just use name for stackable/unique?
			-- For now, simple unique ID
			local uniqueId = itemId .. "_" .. os.time()
			data.Inventory.Items[uniqueId] = {
				Name = itemId,
				Type = itemDef.Type,
				Damage = itemDef.Damage
			}
			
			DataService.UpdateClientHUD(player)
			return true, "Purchased " .. itemId
		end
	else
		return false, "Not enough " .. currency
	end
	
	return false, "Transaction failed"
end

return ShopService
