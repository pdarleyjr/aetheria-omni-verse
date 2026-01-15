--!strict

--[[
	Constants.lua
	
	Centralized game constants for Aetheria: The Omni-Verse.
	These values are used across both server and client to ensure consistency.
	
	@class Constants
]]

local Constants = {}

--[[
	CURRENCY SYSTEM
	Multi-currency economy with different acquisition methods
]]
Constants.Currency = {
	-- Premium currency (purchased with Robux)
	Aether = {
		Name = "Aether",
		Icon = "rbxassetid://0", -- Placeholder
		StartingAmount = 100,
	},
	
	-- Earned currency (gameplay rewards)
	Essence = {
		Name = "Essence",
		Icon = "rbxassetid://0", -- Placeholder
		StartingAmount = 500,
	},
	
	-- Event currency (limited time events)
	Crystals = {
		Name = "Crystals",
		Icon = "rbxassetid://0", -- Placeholder
		StartingAmount = 0,
	},
}

--[[
	SPIRIT RARITY SYSTEM
	Defines drop rates, stat multipliers, and visual indicators
]]
Constants.SpiritRarity = {
	Common = {
		Name = "Common",
		DropRate = 0.60, -- 60%
		StatMultiplier = 1.0,
		Color = Color3.fromRGB(150, 150, 150),
		MaxTraits = 2,
	},
	
	Uncommon = {
		Name = "Uncommon",
		DropRate = 0.25, -- 25%
		StatMultiplier = 1.2,
		Color = Color3.fromRGB(30, 255, 30),
		MaxTraits = 3,
	},
	
	Rare = {
		Name = "Rare",
		DropRate = 0.10, -- 10%
		StatMultiplier = 1.5,
		Color = Color3.fromRGB(30, 100, 255),
		MaxTraits = 4,
	},
	
	Epic = {
		Name = "Epic",
		DropRate = 0.04, -- 4%
		StatMultiplier = 2.0,
		Color = Color3.fromRGB(163, 53, 238),
		MaxTraits = 5,
	},
	
	Legendary = {
		Name = "Legendary",
		DropRate = 0.01, -- 1%
		StatMultiplier = 3.0,
		Color = Color3.fromRGB(255, 170, 0),
		MaxTraits = 5,
		GuaranteedTrait = true, -- Always has at least one unique trait
	},
}

--[[
	SPIRIT TYPES
	Different Spirit types with unique base stats
]]
Constants.SpiritType = {
	Flame = {
		Name = "Flame",
		Element = "Fire",
		BaseStats = {
			Health = 100,
			Attack = 25,
			Defense = 15,
			Speed = 20,
			Luck = 10,
		},
		Color = Color3.fromRGB(255, 85, 0),
	},
	
	Aqua = {
		Name = "Aqua",
		Element = "Water",
		BaseStats = {
			Health = 120,
			Attack = 18,
			Defense = 22,
			Speed = 15,
			Luck = 10,
		},
		Color = Color3.fromRGB(0, 150, 255),
	},
	
	Terra = {
		Name = "Terra",
		Element = "Earth",
		BaseStats = {
			Health = 150,
			Attack = 20,
			Defense = 30,
			Speed = 10,
			Luck = 10,
		},
		Color = Color3.fromRGB(139, 90, 43),
	},
	
	Zephyr = {
		Name = "Zephyr",
		Element = "Air",
		BaseStats = {
			Health = 90,
			Attack = 22,
			Defense = 12,
			Speed = 30,
			Luck = 15,
		},
		Color = Color3.fromRGB(173, 216, 230),
	},
	
	Lux = {
		Name = "Lux",
		Element = "Light",
		BaseStats = {
			Health = 110,
			Attack = 23,
			Defense = 18,
			Speed = 18,
			Luck = 20,
		},
		Color = Color3.fromRGB(255, 255, 200),
	},
	
	Umbra = {
		Name = "Umbra",
		Element = "Dark",
		BaseStats = {
			Health = 105,
			Attack = 28,
			Defense = 16,
			Speed = 19,
			Luck = 12,
		},
		Color = Color3.fromRGB(75, 0, 130),
	},
}

--[[
	REALM SYSTEM
	Player housing configuration and limits
]]
Constants.Realm = {
	-- Realm size and building limits
	MaxRealmSize = Vector3.new(100, 50, 100), -- Studs
	MaxFurnitureItems = 200,
	MaxDecorations = 100,
	MaxSpires = 5, -- Income-generating structures
	
	-- Visitor system
	MaxVisitorsBonus = 10, -- Maximum bonus from unique visitors
	VisitorBonusDuration = 3600, -- 1 hour in seconds
	VisitorBonusPercentage = 0.02, -- 2% income boost per visitor
	
	-- Passive income
	BaseIncomePerMinute = 10, -- Base Essence per minute
	IncomePerSpire = 5, -- Additional Essence per Spire
	MaxIncomeMultiplier = 3.0, -- Cap on total multipliers
	IncomeCollectionInterval = 60, -- Calculate every 60 seconds
	
	-- Realm parties
	PartyDuration = 1800, -- 30 minutes
	PartyMaxPlayers = 20,
	PartyBonusMultiplier = 1.5, -- Income boost during party
	PartyExperienceBonus = 100, -- Flat XP for hosting
	
	-- Building
	PlacementGridSize = 1, -- Snap to 1 stud grid
	MinPlacementHeight = 0,
	MaxPlacementHeight = 45,
}

--[[
	COMBAT SYSTEM
	Damage calculations and combat mechanics
]]
Constants.Combat = {
	-- Damage formulas
	BaseDamageMultiplier = 1.0,
	DefenseReductionFormula = function(defense: number): number
		-- Diminishing returns: defense / (defense + 100)
		return defense / (defense + 100)
	end,
	
	-- Critical hits
	BaseCritChance = 0.05, -- 5%
	CritDamageMultiplier = 1.5,
	LuckToCritRatio = 0.002, -- Each luck point adds 0.2% crit chance
	
	-- Abilities
	GlobalCooldown = 1.0, -- Seconds between any abilities
	MaxAbilitiesPerSpirit = 4,
	
	-- Combat limits
	MaxAttackRange = 50, -- Studs
	MaxAOERadius = 30, -- Studs
	AttackRateLimit = 3, -- Max attacks per second
	
	-- Status effects
	StatusEffectMaxDuration = 30, -- Seconds
	StatusEffectTickRate = 1, -- Update every second
	
	-- Experience and leveling
	BaseExperiencePerKill = 10,
	BossExperienceMultiplier = 5.0,
	ExperiencePerLevel = function(level: number): number
		-- Exponential growth: 100 * (1.1 ^ level)
		return math.floor(100 * math.pow(1.1, level))
	end,
	MaxSpiritLevel = 100,
}

--[[
	BREEDING SYSTEM
	Spirit breeding mechanics and genetics
]]
Constants.Breeding = {
	-- Cooldowns
	BreedingCooldown = 300, -- 5 minutes in seconds
	MaxConcurrentBreedings = 3,
	
	-- Genetics
	TraitInheritanceChance = 0.50, -- 50% chance to inherit from each parent
	MutationBaseChance = 0.05, -- 5% base mutation chance
	MutationIncreasePerBreed = 0.01, -- +1% per breed (stacks)
	MaxMutationChance = 0.20, -- Cap at 20%
	
	-- Stat inheritance
	StatVariance = 0.10, -- ±10% variance from parent average
	MinStatInheritance = 0.80, -- Minimum 80% of parent stat
	MaxStatInheritance = 1.20, -- Maximum 120% of parent stat
	
	-- Trait limits
	MaxTraitsPerSpirit = 5,
	MinTraitsPerSpirit = 1,
	
	-- Costs
	BreedingCostEssence = 1000,
	BreedingCostPerLevel = 50, -- Additional cost per combined parent levels
}

--[[
	SPIRIT MANAGEMENT
	Collection and inventory limits
]]
Constants.Spirit = {
	MaxSpiritsPerPlayer = 200,
	MaxEquippedSpirits = 3,
	StartingSpirits = 1, -- New players start with 1 spirit
	
	-- Leveling
	InitialLevel = 1,
	ExperiencePerCombat = 5,
	ExperiencePerBoss = 25,
	
	-- Trading
	TradingCooldown = 60, -- 1 minute between trades
	MaxTradeSlots = 6,
	MinTradeLevel = 5, -- Must be level 5 to trade
}

--[[
	ECONOMY
	Marketplace and shop configuration
]]
Constants.Economy = {
	-- Marketplace
	MaxListingDuration = 604800, -- 7 days in seconds
	ListingFeePercentage = 0.05, -- 5% fee on sales
	MinListingPrice = 1,
	MaxListingPrice = 1000000,
	
	-- Crafting
	CraftingStationCost = 10000, -- Essence to unlock crafting
	CraftingSuccessRate = 0.90, -- 90% success rate
	CraftingFailureResourceLoss = 0.50, -- Lose 50% of materials on failure
	
	-- Daily rewards
	DailyRewardEssence = 100,
	DailyRewardStreak = 7, -- Days for full streak bonus
	StreakBonusMultiplier = 2.0, -- Double reward at full streak
}

--[[
	BIOMES & DUNGEONS
	World zones and instances
]]
Constants.Biome = {
	-- Dungeon instances
	MaxPlayersPerDungeon = 4,
	DungeonMinDuration = 300, -- 5 minutes
	DungeonMaxDuration = 900, -- 15 minutes
	DungeonTimeoutPenalty = 0.50, -- 50% reduced rewards on timeout
	
	-- Difficulty scaling
	DifficultyMultipliers = {
		Easy = 0.75,
		Normal = 1.0,
		Hard = 1.5,
		Expert = 2.5,
	},
	
	-- Environment effects
	EnvironmentTickRate = 5, -- Apply environmental damage every 5 seconds
}

--[[
	PLAYER PROGRESSION
	Level and rank system
]]
Constants.Player = {
	MaxPlayerLevel = 100,
	InitialLevel = 1,
	ExperiencePerLevel = function(level: number): number
		-- Formula: 100 * level^1.5
		return math.floor(100 * math.pow(level, 1.5))
	end,
	
	-- Ranks (social system)
	Ranks = {
		"Novice",
		"Acolyte",
		"Adept",
		"Expert",
		"Master",
		"Grandmaster",
		"Legend",
	},
	
	-- Daily limits (anti-farming)
	MaxDailyDungeons = 10,
	MaxDailyTrades = 20,
	MaxDailyMarketplaceListings = 50,
}

--[[
	SERVER SETTINGS
	Technical configuration
]]
Constants.Server = {
	-- Data saving
	AutoSaveInterval = 180, -- 3 minutes
	MaxRetries = 3,
	RetryDelay = 5, -- Seconds
	
	-- Performance
	MaxEntitiesPerServer = 1000,
	EntityCleanupInterval = 60,
	
	-- Anti-exploit
	ActionRateLimit = 1.0, -- Max 1 action per second (general)
	SuspiciousActivityThreshold = 10, -- Flag after 10 violations
	
	-- Reserved servers
	RealmServerLifetime = 3600, -- 1 hour
	IdleKickTimeout = 600, -- 10 minutes for reserved servers
}

--[[
	UI SETTINGS
	Interface configuration
]]
Constants.UI = {
	-- Mobile touch targets
	MinTouchTargetSize = UDim2.fromOffset(88, 88),
	
	-- Notifications
	NotificationDuration = 5, -- Seconds
	MaxConcurrentNotifications = 3,
	
	-- Animations
	TweenSpeed = 0.3, -- Default animation duration
	SpringFrequency = 5,
	SpringDamping = 0.7,
	
	-- Colors (Glassmorphism theme)
	PrimaryColor = Color3.fromRGB(138, 43, 226), -- Purple
	SecondaryColor = Color3.fromRGB(75, 0, 130), -- Indigo
	AccentColor = Color3.fromRGB(255, 215, 0), -- Gold
	BackgroundColor = Color3.fromRGB(20, 20, 30),
	TextColor = Color3.fromRGB(255, 255, 255),
	
	-- Glassmorphic effects
	GlassTransparency = 0.3,
	GlassBlurSize = 24,
}

return Constants
