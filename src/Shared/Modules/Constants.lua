local Constants = {}

Constants.SPIRITS = {
	Ignis = {
		Name = "Ignis",
		Type = "Fire",
		BaseStats = { Atk = 10, Def = 5, Spd = 8 },
		Rarity = "Common"
	},
	Aqua = {
		Name = "Aqua",
		Type = "Water",
		BaseStats = { Atk = 6, Def = 8, Spd = 7 },
		Rarity = "Common"
	},
	Terra = {
		Name = "Terra",
		Type = "Earth",
		BaseStats = { Atk = 8, Def = 10, Spd = 4 },
		Rarity = "Common"
	},
	Zephyr = {
		Name = "Zephyr",
		Type = "Air",
		BaseStats = { Atk = 7, Def = 4, Spd = 10 },
		Rarity = "Common"
	},
	-- Uncommon
	Volt = {
		Name = "Volt",
		Type = "Air",
		BaseStats = { Atk = 12, Def = 6, Spd = 12 },
		Rarity = "Uncommon"
	},
	Frost = {
		Name = "Frost",
		Type = "Water",
		BaseStats = { Atk = 9, Def = 12, Spd = 8 },
		Rarity = "Uncommon"
	},
	-- Rare
	Inferno = {
		Name = "Inferno",
		Type = "Fire",
		BaseStats = { Atk = 18, Def = 8, Spd = 10 },
		Rarity = "Rare"
	},
	-- Epic
	Gaia = {
		Name = "Gaia",
		Type = "Earth",
		BaseStats = { Atk = 15, Def = 20, Spd = 5 },
		Rarity = "Epic"
	},
	-- Legendary
	Celestia = {
		Name = "Celestia",
		Type = "Light",
		BaseStats = { Atk = 25, Def = 15, Spd = 20 },
		Rarity = "Legendary"
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

Constants.COMBAT = {
	MAX_DISTANCE = 10,
	COOLDOWN = 0.5,
	DAMAGE = 10,
}

return Constants