--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

local BreedingService = {}

function BreedingService:Init()
	print("[BreedingService] Init")
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	self.BreedSpiritsFunc = Remotes.GetFunction("BreedSpirits")
	
	self.BreedSpiritsFunc.OnServerInvoke = function(player, idA, idB)
		return self:BreedSpirits(player, idA, idB)
	end
end

function BreedingService:Start()
	print("[BreedingService] Start")
end

-- Helper to check if a spirit has a trait
local function HasTrait(spirit, traitName)
	if not spirit.Traits then return false end
	return table.find(spirit.Traits, traitName) ~= nil
end

-- Helper to calculate inheritance chance
local function GetTraitChance(traitName, parentA, parentB)
	local hasA = HasTrait(parentA, traitName)
	local hasB = HasTrait(parentB, traitName)
	
	if hasA and hasB then
		return 0.8 -- High chance if both have it
	elseif hasA or hasB then
		return 0.2 -- Low chance if one has it
	else
		-- Mutation chance
		if traitName == "Shiny" then
			return 0.01 -- 1%
		elseif traitName == "Glitch" then
			return 0.001 -- 0.1%
		end
	end
	return 0
end

function BreedingService:BreedSpirits(player: Player, parentA_ID: string, parentB_ID: string)
	local data = _G.GetData(player)
	if not data then 
		warn("[BreedingService] No data for player " .. player.Name)
		return nil 
	end
	
	-- Cost Check
	if not data.Currencies or (data.Currencies.Essence or 0) < 500 then
		return nil, "Not enough Essence"
	end
	
	local inventory = data.Inventory
	if not inventory or not inventory.Spirits then return nil end
	
	local parentA = inventory.Spirits[parentA_ID]
	local parentB = inventory.Spirits[parentB_ID]
	
	if not parentA or not parentB then
		warn("[BreedingService] Invalid parents specified")
		return nil
	end
	
	if parentA_ID == parentB_ID then
		warn("[BreedingService] Cannot breed spirit with itself")
		return nil
	end
	
	-- Deduct Cost
	data.Currencies.Essence -= 500
	
	-- Determine Offspring Species (50/50 chance)
	local speciesId = (math.random() > 0.5) and parentA.Id or parentB.Id
	local spiritDef = Constants.SPIRITS[speciesId]
	
	-- Generate Unique ID
	local count = 0
	for _ in pairs(inventory.Spirits) do count += 1 end
	local uniqueId = speciesId .. "_" .. (count + 1) .. "_" .. os.time()
	
	-- Calculate Stats
	local newStats = {}
	for stat, _ in pairs(spiritDef.BaseStats) do
		local valA = parentA.Stats[stat] or spiritDef.BaseStats[stat]
		local valB = parentB.Stats[stat] or spiritDef.BaseStats[stat]
		
		local variance = 0.9 + (math.random() * 0.2) -- 0.9 to 1.1
		local avg = (valA + valB) / 2
		
		newStats[stat] = math.floor(avg * variance)
	end
	
	-- Calculate Traits (40% A, 40% B, 20% Mutation)
	local newTraits = {}
	
	-- Parent A Traits
	if parentA.Traits then
		for _, t in ipairs(parentA.Traits) do
			if math.random() < 0.4 then
				if not table.find(newTraits, t) then table.insert(newTraits, t) end
			end
		end
	end
	
	-- Parent B Traits
	if parentB.Traits then
		for _, t in ipairs(parentB.Traits) do
			if math.random() < 0.4 then
				if not table.find(newTraits, t) then table.insert(newTraits, t) end
			end
		end
	end
	
	-- Mutation
	if math.random() < 0.2 then
		local possibleTraits = {"Shiny", "Glitch", "Strong", "Fast", "Tank"}
		local t = possibleTraits[math.random(1, #possibleTraits)]
		if not table.find(newTraits, t) then
			table.insert(newTraits, t)
		end
	end
	
	-- Create Offspring
	local offspring = {
		Id = speciesId,
		UniqueId = uniqueId,
		Name = spiritDef.Name, -- Default name
		Level = 1,
		Exp = 0,
		Stats = newStats,
		Traits = newTraits,
		Obtained = os.time(),
		Parents = {parentA_ID, parentB_ID}
	}
	
	-- Add to Inventory
	inventory.Spirits[uniqueId] = offspring
	
	print(`[BreedingService] Bred {parentA.Name} and {parentB.Name} to create {offspring.Name} ({uniqueId})`)
	
	if _G.UpdateHUD then
		_G.UpdateHUD(player)
	end
	
	return offspring
end

return BreedingService
