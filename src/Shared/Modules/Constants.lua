local Constants = {}

Constants.SPIRITS = {
	Ignis = {
		Name = "Ignis",
		Type = "Fire",
		BaseStats = { Atk = 10, Def = 5, Spd = 8 },
		Rarity = "Common",
		Model = "IgnisModel"
	},
	Aqua = {
		Name = "Aqua",
		Type = "Water",
		BaseStats = { Atk = 6, Def = 8, Spd = 7 },
		Rarity = "Common",
		Model = "AquaModel"
	},
	Terra = {
		Name = "Terra",
		Type = "Earth",
		BaseStats = { Atk = 8, Def = 10, Spd = 4 },
		Rarity = "Common",
		Model = "TerraModel"
	},
	Zephyr = {
		Name = "Zephyr",
		Type = "Air",
		BaseStats = { Atk = 7, Def = 4, Spd = 10 },
		Rarity = "Common",
		Model = "ZephyrModel"
	},
	-- Uncommon
	Volt = {
		Name = "Volt",
		Type = "Air",
		BaseStats = { Atk = 12, Def = 6, Spd = 12 },
		Rarity = "Uncommon",
		Model = "VoltModel"
	},
	Frost = {
		Name = "Frost",
		Type = "Water",
		BaseStats = { Atk = 9, Def = 12, Spd = 8 },
		Rarity = "Uncommon",
		Model = "FrostModel"
	},
	-- Rare
	Inferno = {
		Name = "Inferno",
		Type = "Fire",
		BaseStats = { Atk = 18, Def = 8, Spd = 10 },
		Rarity = "Rare",
		Model = "InfernoModel"
	},
	-- Epic
	Gaia = {
		Name = "Gaia",
		Type = "Earth",
		BaseStats = { Atk = 15, Def = 20, Spd = 5 },
		Rarity = "Epic",
		Model = "GaiaModel"
	},
	-- Legendary
	Celestia = {
		Name = "Celestia",
		Type = "Light",
		BaseStats = { Atk = 25, Def = 15, Spd = 20 },
		Rarity = "Legendary",
		Model = "CelestiaModel"
	}
}

Constants.ASSETS = {
	-- Placeholders for when we have real assets. 
	-- For now, the code will check these, and if invalid/nil, use procedural generation.
	SPIRITS = {
		IgnisModel = "rbxassetid://0",
		AquaModel = "rbxassetid://0",
		TerraModel = "rbxassetid://0",
		ZephyrModel = "rbxassetid://0",
		VoltModel = "rbxassetid://0",
		FrostModel = "rbxassetid://0",
		InfernoModel = "rbxassetid://0",
		GaiaModel = "rbxassetid://0",
		CelestiaModel = "rbxassetid://0",
	},
	ENEMIES = {
		GlitchSlime = "rbxassetid://0",
	},
	BOSSES = {
		GlitchKing = "rbxassetid://0",
	}
}

Constants.SPIRIT_COLORS = {
	Fire = Color3.fromRGB(255, 80, 80),
	Water = Color3.fromRGB(80, 80, 255),
	Earth = Color3.fromRGB(160, 100, 60),
	Air = Color3.fromRGB(200, 255, 255),
	Light = Color3.fromRGB(255, 255, 150),
}

Constants.RARITY = {
	Common = 60,
	Uncommon = 25,
	Rare = 10,
	Epic = 4,
	Legendary = 1
}

Constants.GACHA = {
	COST = {
		Currency = "Essence",
		Amount = 100
	},
	TEN_PULL_BONUS = true -- Maybe guaranteed uncommon+?
}

Constants.REALM_ISLAND_SIZE = Vector3.new(200, 20, 200)
Constants.REALM_GRID_SPACING = 300 -- As requested: x = col * 300
Constants.REALM_GRID_WIDTH = 100

Constants.STARTING_SPIRIT = "Ignis"

Constants.BIOMES = {
	{
		Name = "Glitch Wastes",
		Color = Color3.fromRGB(255, 0, 255),
		Position = Vector3.new(-50, 5, 50),
		Description = "A chaotic realm of corrupted data."
	},
	{
		Name = "Azure Sea",
		Color = Color3.fromRGB(0, 100, 255),
		Position = Vector3.new(0, 5, 50),
		Description = "A vast ocean of tranquility."
	},
	{
		Name = "Celestial Arena",
		Color = Color3.fromRGB(255, 215, 0),
		Position = Vector3.new(50, 5, 50),
		Description = "Where legends prove their worth."
	}
}

Constants.ZONES = {
	["Glitch Wastes"] = {
		Center = Vector3.new(1000, 100, 1000),
		Size = Vector3.new(400, 20, 400),
		BaseColor = Color3.fromRGB(20, 0, 20),
		PlatformColor = Color3.fromRGB(40, 0, 40),
		AtmosphereColor = Color3.fromRGB(100, 0, 100)
	},
	["Azure Sea"] = {
		Center = Vector3.new(10000, 0, 0),
		Size = Vector3.new(2048, 50, 2048),
		BaseColor = Color3.fromRGB(0, 100, 255),
		PlatformColor = Color3.fromRGB(0, 80, 200),
		AtmosphereColor = Color3.fromRGB(150, 200, 255)
	}
}

Constants.VEHICLES = {
	Skiff = {
		Name = "Skiff",
		Speed = 50,
		TurnSpeed = 2,
		Model = "SkiffModel"
	}
}

Constants.FISH = {
	NeonGuppy = {
		Name = "Neon Guppy",
		Rarity = "Common",
		Value = 10,
		Difficulty = 1
	},
	VoidBass = {
		Name = "Void Bass",
		Rarity = "Rare",
		Value = 50,
		Difficulty = 3
	}
}

Constants.BOSSES = {
	GlitchKing = {
		Name = "The Glitch King",
		Health = 50000,
		Damage = 50,
		Model = "GlitchKing", -- Placeholder for model name
		Rewards = {
			Essence = 500,
			Aether = 50,
			Exp = 1000
		},
		Phases = {
			{ Threshold = 1.0, Name = "Normal" },
			{ Threshold = 0.5, Name = "Enraged" }
		},
		Attacks = {
			Spike = { Damage = 30, Range = 20, Cooldown = 5 },
			Corruption = { Damage = 10, Range = 100, Cooldown = 8, Duration = 5 }
		}
	},
	GlitchOverlord = {
		Name = "Glitch Overlord",
		Health = 10000,
		Damage = 50,
		Model = "GlitchOverlord",
		Rewards = {
			Essence = 1000,
			Aether = 100,
			Exp = 2000
		},
		Phases = {
			{ Threshold = 1.0, Name = "Normal" }
		},
		Attacks = {
			Spike = { Damage = 40, Range = 25, Cooldown = 4 }
		}
	}
}

Constants.ITEMS = {
	SpiritIncubator = {
		Id = "SpiritIncubator",
		Name = "Spirit Incubator",
		Description = "A device used to incubate Spirit eggs and facilitate breeding.",
		Type = "Furniture",
		Rarity = "Rare",
		MaxStack = 1
	}
}

Constants.PRODUCTS = {
	SpiritKeys = 12345678, -- Placeholder
	BlueprintPack = 87654321, -- Placeholder
}

Constants.GAMEPASSES = {
	OmniPass = 11223344, -- Placeholder
}

Constants.SKILLS = {
	Fireball = {
		Name = "Fireball",
		Description = "Launch a ball of fire that explodes on impact.",
		Damage = 25,
		Cooldown = 5,
		Speed = 80,
		Range = 100,
		Cost = 10, -- Essence cost
		Radius = 10,
	},
	Dash = {
		Name = "Dash",
		Description = "Quickly dash forward to evade attacks.",
		Distance = 30,
		Cooldown = 3,
		Cost = 15, -- Essence cost
		Duration = 0.2,
	}
}

Constants.COMBAT = {
	MAX_DISTANCE = 10,
	COOLDOWN = 0.5,
	DAMAGE = 10,
	CRITICAL_CHANCE = 0.15,
	CRITICAL_MULTIPLIER = 2,
}

-- Accessibility Settings
Constants.SETTINGS = {
	ScreenShakeEnabled = true,
	FlashEffectsEnabled = true,
	ScreenShakeIntensity = 1.0, -- 0.0-1.0 multiplier
	DamageNumbersEnabled = true,
}

-- Hit-stop frames configuration
Constants.HITSTOP = {
	NORMAL_DURATION = 0.033, -- ~2 frames at 60fps
	CRITICAL_DURATION = 0.066, -- ~4 frames at 60fps
	DEATH_DURATION = 0.1, -- ~6 frames for death impact
}

-- Damage type colors for particles and numbers
Constants.DAMAGE_TYPE_COLORS = {
	Physical = Color3.fromRGB(255, 255, 255),
	Fire = Color3.fromRGB(255, 100, 50),
	Ice = Color3.fromRGB(100, 200, 255),
	Lightning = Color3.fromRGB(255, 255, 100),
	Poison = Color3.fromRGB(100, 255, 100),
	Dark = Color3.fromRGB(150, 50, 200),
	Critical = Color3.fromRGB(255, 200, 50), -- Gold for crits
}

Constants.ENEMY = {
	ZONE_DIFFICULTY_MULTIPLIERS = {
		{MaxDistance = 100, Multiplier = 1.0},
		{MaxDistance = 300, Multiplier = 1.5},
		{MaxDistance = 500, Multiplier = 2.0},
		{MaxDistance = math.huge, Multiplier = 3.0},
	},
	FLEE_HEALTH_THRESHOLD = 0.2,
	TELEGRAPH_DURATION = 0.5,
}

Constants.CURRENCY_DROP_RATES = {
	GlitchSlime = { Gold = { Min = 5, Max = 15 } },
	GlitchKing = { Gold = { Min = 100, Max = 250 } },
	GlitchOverlord = { Gold = { Min = 500, Max = 1000 } },
	Default = { Gold = { Min = 1, Max = 5 } },
}

Constants.LEVELING = {
	MAX_LEVEL = 100,
	BASE_EXP = 100, -- XP needed for level 2
	EXP_EXPONENT = 1.5, -- Curve factor
}

Constants.REALM_ACCESS = {
	PRIVATE = "Private",
	FRIENDS = "Friends",
	PUBLIC = "Public"
}

Constants.CLANS = {
	CREATION_COST = {
		Currency = "Essence",
		Amount = 1000
	},
	MAX_MEMBERS = 50
}

Constants.SHOP_ITEMS = {
	-- Stat Upgrades
	{id = "stat_health_1", name = "Health +10", cost = 100, type = "stat", stat = "MaxHealth", value = 10},
	{id = "stat_health_2", name = "Health +25", cost = 250, type = "stat", stat = "MaxHealth", value = 25},
	{id = "stat_health_3", name = "Health +50", cost = 500, type = "stat", stat = "MaxHealth", value = 50},
	{id = "stat_attack_1", name = "Attack +5", cost = 150, type = "stat", stat = "Attack", value = 5},
	{id = "stat_attack_2", name = "Attack +10", cost = 350, type = "stat", stat = "Attack", value = 10},
	{id = "stat_speed_1", name = "Speed +5", cost = 100, type = "stat", stat = "Speed", value = 5},
	{id = "stat_speed_2", name = "Speed +10", cost = 250, type = "stat", stat = "Speed", value = 10},
	
	-- Weapons - Common (50 Gold)
	{id = "weapon_wooden_sword", name = "Wooden Sword", cost = 50, type = "weapon", rarity = "Common", stats = {damage = 5}},
	{id = "weapon_iron_dagger", name = "Iron Dagger", cost = 50, type = "weapon", rarity = "Common", stats = {damage = 4, speed = 2}},
	
	-- Weapons - Rare (200 Gold)
	{id = "weapon_steel_sword", name = "Steel Sword", cost = 200, type = "weapon", rarity = "Rare", stats = {damage = 15}},
	{id = "weapon_fire_staff", name = "Fire Staff", cost = 200, type = "weapon", rarity = "Rare", stats = {damage = 12, magic = 5}},
	
	-- Weapons - Epic (500 Gold)
	{id = "weapon_shadow_blade", name = "Shadow Blade", cost = 500, type = "weapon", rarity = "Epic", stats = {damage = 30, critChance = 10}},
	{id = "weapon_thunder_hammer", name = "Thunder Hammer", cost = 500, type = "weapon", rarity = "Epic", stats = {damage = 35, stun = 5}},
	
	-- Weapons - Legendary (1000 Gold)
	{id = "weapon_divine_sword", name = "Divine Sword", cost = 1000, type = "weapon", rarity = "Legendary", stats = {damage = 50, critChance = 15, lifesteal = 5}},
	{id = "weapon_void_scythe", name = "Void Scythe", cost = 1000, type = "weapon", rarity = "Legendary", stats = {damage = 45, aoeRadius = 10, drain = 10}},
	
	-- Consumables
	{id = "consumable_health_potion", name = "Health Potion", cost = 25, type = "consumable", effect = "heal", value = 50},
	{id = "consumable_large_health_potion", name = "Large Health Potion", cost = 75, type = "consumable", effect = "heal", value = 150},
	{id = "consumable_attack_boost", name = "Attack Boost", cost = 50, type = "consumable", effect = "attackBoost", value = 20, duration = 60},
	{id = "consumable_speed_boost", name = "Speed Boost", cost = 50, type = "consumable", effect = "speedBoost", value = 10, duration = 60},
	{id = "consumable_shield_potion", name = "Shield Potion", cost = 100, type = "consumable", effect = "shield", value = 100, duration = 30},
	
	-- Cosmetics
	{id = "cosmetic_flame_aura", name = "Flame Aura", cost = 500, type = "cosmetic", cosmeticType = "aura", assetId = "flame_aura"},
	{id = "cosmetic_ice_trail", name = "Ice Trail", cost = 300, type = "cosmetic", cosmeticType = "trail", assetId = "ice_trail"},
	{id = "cosmetic_golden_crown", name = "Golden Crown", cost = 1000, type = "cosmetic", cosmeticType = "hat", assetId = "golden_crown"},
}

-- Build lookup for quick access
Constants.SHOP_CATALOG = {}
for _, item in ipairs(Constants.SHOP_ITEMS) do
	Constants.SHOP_CATALOG[item.id] = item
end

return Constants