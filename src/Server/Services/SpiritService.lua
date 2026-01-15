--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
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
	
	-- Listen for EquipSpirit
	local EquipSpiritEvent = Remotes.GetEvent("EquipSpirit")
	EquipSpiritEvent.OnServerEvent:Connect(function(player, spiritUniqueId)
		self:EquipSpirit(player, spiritUniqueId)
	end)

	-- Listen for players
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
		player.CharacterAdded:Connect(function(char)
			task.wait(0.5)
			self:RefreshSpiritVisual(player)
		end)
	end)
	
	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:OnPlayerAdded(player)
			if player.Character then
				self:RefreshSpiritVisual(player)
			end
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
		local newSpirit = self:AddSpirit(player, starterId)
		if newSpirit then
			self:EquipSpirit(player, newSpirit.UniqueId)
		end
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

function SpiritService:EquipSpirit(player: Player, spiritUniqueId: string)
	local data = _G.GetData(player)
	if not data then return end

	local inventory = data.Inventory
	if not inventory.Spirits then return end

	local spirit = inventory.Spirits[spiritUniqueId]
	if not spirit then
		warn(`[SpiritService] Player {player.Name} tried to equip invalid spirit {spiritUniqueId}`)
		return
	end

	inventory.EquippedSpirit = spiritUniqueId
	print(`[SpiritService] {player.Name} equipped {spirit.Name}`)

	if _G.UpdateHUD then
		_G.UpdateHUD(player)
	end
	
	-- Update character visuals
	self:UpdateCharacterSpirit(player, spirit)
end

function SpiritService:UpdateCharacterSpirit(player: Player, spirit: any)
	local character = player.Character
	if not character or not character.PrimaryPart then return end
	
	-- Remove existing spirit
	local existing = character:FindFirstChild("ActiveSpirit")
	if existing then existing:Destroy() end
	
	if not spirit then return end
	
	-- Create visual
	local spiritDef = Constants.SPIRITS[spirit.Id]
	if not spiritDef then return end
	
	local part = Instance.new("Part")
	part.Name = "ActiveSpirit"
	part.Size = Vector3.new(1.5, 1.5, 1.5)
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.Massless = true
	
	local color = Constants.SPIRIT_COLORS[spiritDef.Type] or Color3.new(1, 1, 1)
	part.Color = color
	
	-- Add particles or light
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 8
	light.Brightness = 1.5
	light.Parent = part
	
	-- Position relative to head/shoulder
	local head = character:FindFirstChild("Head")
	if head then
		part.CFrame = head.CFrame * CFrame.new(2, 1, 0)
	else
		part.CFrame = character.PrimaryPart.CFrame * CFrame.new(2, 2, 0)
	end
	
	part.Parent = character
	
	-- Weld to character so it moves with them
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head or character.PrimaryPart
	weld.Part1 = part
	weld.Parent = part
	
	print(`[SpiritService] Spawning spirit visual for {player.Name}: {spirit.Name}`)
end

function SpiritService:RefreshSpiritVisual(player: Player)
	local data = _G.GetData(player)
	if not data or not data.Inventory then return end
	
	local equippedId = data.Inventory.EquippedSpirit
	if not equippedId then return end
	
	local spirit = data.Inventory.Spirits[equippedId]
	if spirit then
		self:UpdateCharacterSpirit(player, spirit)
	end
end

function SpiritService:Start()
	print("[SpiritService] Started")
end

return SpiritService