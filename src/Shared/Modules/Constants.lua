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
	}
}

Constants.RARITY = {
	Common = 60,
	Uncommon = 25,
	Rare = 10,
	Epic = 4,
	Legendary = 1
}

Constants.REALM_ISLAND_SIZE = Vector3.new(200, 20, 200)
Constants.REALM_GRID_SPACING = 300 -- As requested: x = col * 300
Constants.REALM_GRID_WIDTH = 100

Constants.STARTING_SPIRIT = "Ignis"

return Constants