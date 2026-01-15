--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
-- We need to wait for DataService to be loaded. 
-- Since we are in the same folder and loaded by Main, we can require it directly if we knew the order,
-- or use the global _G.GetData which DataService sets up.
-- However, requiring the module is safer if we can.
-- But Main loads them in directory order (alphabetical usually).
-- DataService (D) comes before SpiritService (S). So it should be required already.
-- But Main requires them, then Inits them.
-- So inside Init/Start, we can access it.

local SpiritService = {}

function SpiritService:Init()
	-- Listen for players
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)
	
	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:OnPlayerAdded(player)
		end)
	end
end

function SpiritService:OnPlayerAdded(player: Player)
	-- Wait for data to be ready
	local data = nil
	for i = 1, 10 do -- Try for 10 seconds
		if _G.GetData then
			data = _G.GetData(player)
			if data then break end
		end
		task.wait(1)
	end
	
	if not data then
		warn(`[SpiritService] Could not get data for {player.Name}`)
		return
	end
	
	self:CheckStarterSpirit(player, data)
end

function SpiritService:CheckStarterSpirit(player: Player, data: any)
	local inventory = data.Inventory
	if not inventory.Spirits then
		inventory.Spirits = {}
	end
	
	-- Check if they have any spirits (or specific flag)
	local hasSpirits = false
	for _, _ in pairs(inventory.Spirits) do
		hasSpirits = true
		break
	end
	
	if not hasSpirits then
		local starterId = Constants.STARTING_SPIRIT
		local starterDef = Constants.SPIRITS[starterId]
		
		if starterDef then
			-- Create spirit instance data
			local newSpirit = {
				Id = starterId,
				Name = starterDef.Name,
				Level = 1,
				Exp = 0,
				Stats = table.clone(starterDef.BaseStats),
				Obtained = os.time()
			}
			
			-- Add to inventory (using a unique key, e.g., GUID or just simple index for now)
			-- For simplicity, let's use a simple string key "Spirit_1"
			inventory.Spirits["Spirit_1"] = newSpirit
			
			-- Equip it
			if not inventory.Equipped then
				inventory.Equipped = {}
			end
			inventory.Equipped["Main"] = "Spirit_1"
			
			print(`[SpiritService] Gave Starter Spirit ({starterDef.Name}) to {player.Name}`)
		end
	end
end

function SpiritService:Start()
	print("[SpiritService] Started")
end

return SpiritService