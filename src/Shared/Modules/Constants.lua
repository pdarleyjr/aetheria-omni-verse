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
		Center = Vector3.new(0, 5, 50),
		Size = Vector3.new(500, 50, 500),
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

return Constants