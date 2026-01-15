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
	print("[SpiritService] Init called")
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
	print(`[SpiritService] OnPlayerAdded called for {player.Name}`)
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
		self:AddSpirit(player, starterId)
	end
end

function SpiritService:AddSpirit(player: Player, spiritId: string)
	local data = _G.GetData(player)
	if not data then return nil end
	
	local spiritDef = Constants.SPIRITS[spiritId]
	if not spiritDef then return nil end
	
	local inventory = data.Inventory
	if not inventory.Spirits then inventory.Spirits = {} end
	
	-- Generate unique ID (simple counter for now, or GUID)
	local count = 0
	for _ in pairs(inventory.Spirits) do count += 1 end
	local uniqueId = spiritId .. "_" .. (count + 1) .. "_" .. os.time()
	
	local newSpirit = {
		Id = spiritId,
		UniqueId = uniqueId,
		Name = spiritDef.Name,
		Level = 1,
		Exp = 0,
		Stats = table.clone(spiritDef.BaseStats),
		Obtained = os.time()
	}
	
	inventory.Spirits[uniqueId] = newSpirit
	
	print(`[SpiritService] Added Spirit {spiritDef.Name} to {player.Name}`)
	
	if _G.UpdateHUD then
		_G.UpdateHUD(player)
	end
	
	return newSpirit
end

function SpiritService:Start()
	print("[SpiritService] Started")
end

return SpiritService