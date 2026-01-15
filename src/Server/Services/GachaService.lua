--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local SpiritService = require(script.Parent.SpiritService)

local GachaService = {}

function GachaService:Init()
	print("[GachaService] Init")
	
	-- Create RemoteFunction
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end
	
	local gachaFolder = remotesFolder:FindFirstChild("Gacha")
	if not gachaFolder then
		gachaFolder = Instance.new("Folder")
		gachaFolder.Name = "Gacha"
		gachaFolder.Parent = remotesFolder
	end
	
	local summonFunc = gachaFolder:FindFirstChild("Summon")
	if not summonFunc then
		summonFunc = Instance.new("RemoteFunction")
		summonFunc.Name = "Summon"
		summonFunc.Parent = gachaFolder
	end
	
	summonFunc.OnServerInvoke = function(player, amount)
		return self:Summon(player, amount)
	end
end

function GachaService:Start()
	print("[GachaService] Started")
end

function GachaService:Summon(player: Player, amount: number)
	amount = amount or 1
	if amount ~= 1 and amount ~= 10 then 
		return {Success = false, Message = "Invalid amount"} 
	end
	
	local data = _G.GetData(player)
	if not data then 
		return {Success = false, Message = "Data not loaded"} 
	end
	
	local cost = Constants.GACHA.COST.Amount * amount
	local currency = Constants.GACHA.COST.Currency
	
	if data.Currencies[currency] < cost then
		return {Success = false, Message = "Insufficient funds"}
	end
	
	-- Deduct cost
	data.Currencies[currency] -= cost
	if _G.UpdateHUD then 
		_G.UpdateHUD(player) 
	end
	
	local results = {}
	
	for i = 1, amount do
		local rarity = self:RollRarity()
		local spiritId = self:RollSpirit(rarity)
		
		local spirit = SpiritService:AddSpirit(player, spiritId)
		if spirit then
			table.insert(results, {
				Name = spirit.Name,
				Rarity = rarity,
				Id = spiritId
			})
		end
	end
	
	return {Success = true, Results = results}
end

function GachaService:RollRarity()
	local total = 0
	for _, v in pairs(Constants.RARITY) do total += v end
	
	local roll = math.random(1, total)
	local current = 0
	
	for rarity, weight in pairs(Constants.RARITY) do
		current += weight
		if roll <= current then
			return rarity
		end
	end
	return "Common"
end

function GachaService:RollSpirit(rarity: string)
	local candidates = {}
	for id, def in pairs(Constants.SPIRITS) do
		if def.Rarity == rarity then
			table.insert(candidates, id)
		end
	end
	
	if #candidates == 0 then
		-- Fallback to Common if no spirits of this rarity found
		if rarity ~= "Common" then
			return self:RollSpirit("Common")
		end
		return "Ignis" -- Ultimate fallback
	end
	
	return candidates[math.random(1, #candidates)]
end

return GachaService
