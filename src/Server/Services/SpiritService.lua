--!strict
--[[
	SpiritService.lua
	Manages Spirit collection, breeding, genetics, stat generation, and equipping.
	
	Features:
	- Spirit generation with randomized stats and rarities
	- Breeding system with genetic trait inheritance
	- Spirit leveling and experience
	- Equipping spirits to player slots
	- Spirit inventory management
]]

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Only run on server
if not RunService:IsServer() then
	error("SpiritService can only be required on the server")
end

-- Services
local DataService = require(ServerScriptService.Server.Services.DataService)

-- Types
type SpiritData = {
	Id: string,
	TypeId: string,
	Level: number,
	Experience: number,
	Rarity: string,
	Traits: { string },
	Stats: {
		Health: number,
		Attack: number,
		Defense: number,
		Speed: number,
	},
	BredCount: number,
	ParentIds: { string }?,
}

type SpiritType = {
	Name: string,
	BaseStats: {
		Health: number,
		Attack: number,
		Defense: number,
		Speed: number,
	},
	PossibleTraits: { string },
}

-- Constants
local BREEDING_COOLDOWN = 300 -- 5 minutes in seconds
local MAX_TRAITS = 5
local MUTATION_CHANCE = 0.05 -- 5% chance for trait mutation
local MAX_EQUIPPED_SPIRITS = 3

-- Rarity chances and multipliers
local RARITY_CHANCES = {
	{ Name = "Common", Chance = 0.60, StatMultiplier = 1.0 },
	{ Name = "Uncommon", Chance = 0.25, StatMultiplier = 1.2 },
	{ Name = "Rare", Chance = 0.10, StatMultiplier = 1.5 },
	{ Name = "Epic", Chance = 0.04, StatMultiplier = 2.0 },
	{ Name = "Legendary", Chance = 0.01, StatMultiplier = 3.0 },
}

-- Spirit type definitions (simplified - in production, load from Shared/Data)
local SPIRIT_TYPES: { [string]: SpiritType } = {
	["fire_spirit"] = {
		Name = "Fire Spirit",
		BaseStats = {
			Health = 100,
			Attack = 25,
			Defense = 10,
			Speed = 15,
		},
		PossibleTraits = { "Blazing", "Heat Resistant", "Fierce", "Quick" },
	},
	["water_spirit"] = {
		Name = "Water Spirit",
		BaseStats = {
			Health = 120,
			Attack = 20,
			Defense = 15,
			Speed = 10,
		},
		PossibleTraits = { "Flowing", "Aquatic", "Calm", "Regenerative" },
	},
	["earth_spirit"] = {
		Name = "Earth Spirit",
		BaseStats = {
			Health = 150,
			Attack = 15,
			Defense = 25,
			Speed = 5,
		},
		PossibleTraits = { "Sturdy", "Grounded", "Resilient", "Steadfast" },
	},
	["air_spirit"] = {
		Name = "Air Spirit",
		BaseStats = {
			Health = 80,
			Attack = 30,
			Defense = 5,
			Speed = 25,
		},
		PossibleTraits = { "Swift", "Evasive", "Agile", "Windborne" },
	},
}

-- Service
local SpiritService = {
	_breedingCooldowns = {} :: { [string]: number }, -- playerId_spiritId -> timestamp
	_equippedSpirits = {} :: { [number]: { string } }, -- userId -> array of spirit IDs
}

-- Generate random rarity based on weighted chances
local function getRandomRarity(): (string, number)
	local roll = math.random()
	local cumulative = 0
	
	for _, rarityData in RARITY_CHANCES do
		cumulative += rarityData.Chance
		if roll <= cumulative then
			return rarityData.Name, rarityData.StatMultiplier
		end
	end
	
	return "Common", 1.0
end

-- Generate random stats for a spirit
local function generateStats(baseStats: any, rarityMultiplier: number): any
	local variance = 0.15 -- ±15% variance
	
	return {
		Health = math.floor(baseStats.Health * rarityMultiplier * (1 + math.random() * variance * 2 - variance)),
		Attack = math.floor(baseStats.Attack * rarityMultiplier * (1 + math.random() * variance * 2 - variance)),
		Defense = math.floor(baseStats.Defense * rarityMultiplier * (1 + math.random() * variance * 2 - variance)),
		Speed = math.floor(baseStats.Speed * rarityMultiplier * (1 + math.random() * variance * 2 - variance)),
	}
end

-- Generate random traits
local function generateTraits(possibleTraits: { string }, count: number): { string }
	local shuffled = table.clone(possibleTraits)
	
	-- Fisher-Yates shuffle
	for i = #shuffled, 2, -1 do
		local j = math.random(i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	
	local selected = {}
	for i = 1, math.min(count, #shuffled) do
		table.insert(selected, shuffled[i])
	end
	
	return selected
end

-- Award a new spirit to player
function SpiritService:AwardSpirit(player: Player, spiritTypeId: string): SpiritData?
	local spiritType = SPIRIT_TYPES[spiritTypeId]
	if not spiritType then
		warn(`Invalid spirit type: {spiritTypeId}`)
		return nil
	end
	
	-- Generate spirit data
	local rarity, rarityMultiplier = getRandomRarity()
	local spiritId = `{player.UserId}_{spiritTypeId}_{os.time()}_{math.random(1000)}`
	
	local spiritData: SpiritData = {
		Id = spiritId,
		TypeId = spiritTypeId,
		Level = 1,
		Experience = 0,
		Rarity = rarity,
		Traits = generateTraits(spiritType.PossibleTraits, math.random(1, 3)),
		Stats = generateStats(spiritType.BaseStats, rarityMultiplier),
		BredCount = 0,
		ParentIds = nil,
	}
	
	-- Add to player's collection
	DataService:AddSpirit(player, spiritData)
	
	print(`Awarded {rarity} {spiritType.Name} to {player.Name}`)
	return spiritData
end

-- Calculate offspring traits from two parents
local function inheritTraits(parent1: SpiritData, parent2: SpiritData): { string }
	local allTraits = {}
	local traitSet = {}
	
	-- Collect unique traits from both parents
	for _, trait in parent1.Traits do
		if not traitSet[trait] then
			table.insert(allTraits, trait)
			traitSet[trait] = true
		end
	end
	
	for _, trait in parent2.Traits do
		if not traitSet[trait] then
			table.insert(allTraits, trait)
			traitSet[trait] = true
		end
	end
	
	-- Randomly inherit traits (50% chance for each parent trait)
	local inherited = {}
	for _, trait in allTraits do
		if math.random() < 0.5 and #inherited < MAX_TRAITS then
			table.insert(inherited, trait)
		end
	end
	
	-- Mutation chance - add random trait
	if math.random() < MUTATION_CHANCE then
		local parentType = SPIRIT_TYPES[parent1.TypeId]
		if parentType then
			local possibleTraits = parentType.PossibleTraits
			local newTrait = possibleTraits[math.random(#possibleTraits)]
			if not traitSet[newTrait] and #inherited < MAX_TRAITS then
				table.insert(inherited, newTrait)
				print("Trait mutation occurred!")
			end
		end
	end
	
	-- Ensure at least one trait
	if #inherited == 0 and #allTraits > 0 then
		table.insert(inherited, allTraits[math.random(#allTraits)])
	end
	
	return inherited
end

-- Calculate offspring stats from parents
local function inheritStats(parent1: SpiritData, parent2: SpiritData, rarityMultiplier: number): any
	return {
		Health = math.floor((parent1.Stats.Health + parent2.Stats.Health) / 2 * rarityMultiplier * (0.9 + math.random() * 0.2)),
		Attack = math.floor((parent1.Stats.Attack + parent2.Stats.Attack) / 2 * rarityMultiplier * (0.9 + math.random() * 0.2)),
		Defense = math.floor((parent1.Stats.Defense + parent2.Stats.Defense) / 2 * rarityMultiplier * (0.9 + math.random() * 0.2)),
		Speed = math.floor((parent1.Stats.Speed + parent2.Stats.Speed) / 2 * rarityMultiplier * (0.9 + math.random() * 0.2)),
	}
end

-- Breed two spirits
function SpiritService:BreedSpirits(player: Player, parentId1: string, parentId2: string): SpiritData?
	local playerData = DataService:GetPlayerData(player)
	if not playerData then
		return nil
	end
	
	-- Get parent spirits
	local parent1 = playerData.Spirits[parentId1]
	local parent2 = playerData.Spirits[parentId2]
	
	if not parent1 or not parent2 then
		warn(`Invalid parent spirit IDs`)
		return nil
	end
	
	-- Check if parents are same type
	if parent1.TypeId ~= parent2.TypeId then
		warn(`Cannot breed different spirit types`)
		return nil
	end
	
	-- Check breeding cooldowns
	local cooldownKey1 = `{player.UserId}_{parentId1}`
	local cooldownKey2 = `{player.UserId}_{parentId2}`
	local currentTime = os.time()
	
	if self._breedingCooldowns[cooldownKey1] and (currentTime - self._breedingCooldowns[cooldownKey1]) < BREEDING_COOLDOWN then
		warn(`Parent 1 is on breeding cooldown`)
		return nil
	end
	
	if self._breedingCooldowns[cooldownKey2] and (currentTime - self._breedingCooldowns[cooldownKey2]) < BREEDING_COOLDOWN then
		warn(`Parent 2 is on breeding cooldown`)
		return nil
	end
	
	-- Generate offspring
	local rarity, rarityMultiplier = getRandomRarity()
	local offspringId = `{player.UserId}_{parent1.TypeId}_bred_{os.time()}_{math.random(1000)}`
	
	local offspring: SpiritData = {
		Id = offspringId,
		TypeId = parent1.TypeId,
		Level = 1,
		Experience = 0,
		Rarity = rarity,
		Traits = inheritTraits(parent1, parent2),
		Stats = inheritStats(parent1, parent2, rarityMultiplier),
		BredCount = 0,
		ParentIds = { parentId1, parentId2 },
	}
	
	-- Add to collection
	DataService:AddSpirit(player, offspring)
	
	-- Set cooldowns
	self._breedingCooldowns[cooldownKey1] = currentTime
	self._breedingCooldowns[cooldownKey2] = currentTime
	
	-- Increment bred count
	parent1.BredCount += 1
	parent2.BredCount += 1
	
	print(`Bred new {rarity} spirit for {player.Name}`)
	return offspring
end

-- Equip spirit to slot
function SpiritService:EquipSpirit(player: Player, spiritId: string, slot: number): boolean
	if slot < 1 or slot > MAX_EQUIPPED_SPIRITS then
		return false
	end
	
	local playerData = DataService:GetPlayerData(player)
	if not playerData then
		return false
	end
	
	-- Check if spirit exists
	if not playerData.Spirits[spiritId] then
		warn(`Spirit {spiritId} not found`)
		return false
	end
	
	-- Initialize equipped array if needed
	local userId = player.UserId
	if not self._equippedSpirits[userId] then
		self._equippedSpirits[userId] = {}
	end
	
	-- Equip spirit
	self._equippedSpirits[userId][slot] = spiritId
	print(`Equipped spirit {spiritId} to slot {slot} for {player.Name}`)
	
	return true
end

-- Get equipped spirits
function SpiritService:GetEquippedSpirits(player: Player): { SpiritData }
	local equipped = {}
	local userId = player.UserId
	
	if not self._equippedSpirits[userId] then
		return equipped
	end
	
	local playerData = DataService:GetPlayerData(player)
	if not playerData then
		return equipped
	end
	
	for _, spiritId in self._equippedSpirits[userId] do
		local spirit = playerData.Spirits[spiritId]
		if spirit then
			table.insert(equipped, spirit)
		end
	end
	
	return equipped
end

-- Level up spirit
function SpiritService:LevelUpSpirit(player: Player, spiritId: string): boolean
	local playerData = DataService:GetPlayerData(player)
	if not playerData then
		return false
	end
	
	local spirit = playerData.Spirits[spiritId]
	if not spirit then
		return false
	end
	
	-- Increase stats on level up
	spirit.Level += 1
	spirit.Stats.Health = math.floor(spirit.Stats.Health * 1.1)
	spirit.Stats.Attack = math.floor(spirit.Stats.Attack * 1.1)
	spirit.Stats.Defense = math.floor(spirit.Stats.Defense * 1.1)
	spirit.Stats.Speed = math.floor(spirit.Stats.Speed * 1.1)
	
	print(`Leveled up spirit {spiritId} to level {spirit.Level}`)
	return true
end

-- Add experience to spirit
function SpiritService:AddExperience(player: Player, spiritId: string, amount: number): ()
	local playerData = DataService:GetPlayerData(player)
	if not playerData then
		return
	end
	
	local spirit = playerData.Spirits[spiritId]
	if not spirit then
		return
	end
	
	spirit.Experience += amount
	
	-- Check if leveled up (100 exp per level)
	local expNeeded = spirit.Level * 100
	if spirit.Experience >= expNeeded then
		spirit.Experience -= expNeeded
		self:LevelUpSpirit(player, spiritId)
	end
end

-- Initialize service
function SpiritService:Init(): ()
	print("Initializing SpiritService...")
	print("SpiritService initialized")
end

-- Start service
function SpiritService:Start(): ()
	print("Starting SpiritService...")
	
	-- Cleanup on player leave
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		self._equippedSpirits[player.UserId] = nil
	end)
	
	print("SpiritService started")
end

return SpiritService
