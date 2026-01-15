--!strict
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

local WorkspaceService = {}

function WorkspaceService:Init()
	print("[WorkspaceService] Init")
end

function WorkspaceService:Start()
	print("[WorkspaceService] Start")
	self:CreateSpawnHub()
	self:SpawnPortals()
	self:CreateTestDummy()
	self:SetupEnvironment()
	self:SpawnSummoningAltar()
end

function WorkspaceService:CreateSpawnHub()
	local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
	if not spawnLocation then
		local part = Instance.new("Part")
		part.Name = "SpawnLocation"
		part.Size = Vector3.new(150, 1, 150)
		part.Position = Vector3.new(0, 0, 0)
		part.Anchored = true
		part.Material = Enum.Material.SmoothPlastic
		part.Color = Color3.fromRGB(50, 50, 60)
		part.Parent = Workspace
		
		local spawn = Instance.new("SpawnLocation")
		spawn.Size = Vector3.new(12, 1, 12)
		spawn.Position = Vector3.new(0, 1, 0)
		spawn.Anchored = true
		spawn.Transparency = 1
		spawn.CanCollide = false
		spawn.Parent = Workspace
	end
	
	-- Welcome Sign
	local sign = Instance.new("Part")
	sign.Name = "WelcomeSign"
	sign.Size = Vector3.new(20, 10, 1)
	sign.Position = Vector3.new(0, 10, -60)
	sign.Anchored = true
	sign.Color = Color3.fromRGB(20, 20, 20)
	sign.Parent = Workspace
	
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.Parent = sign
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "AETHERIA"
	label.TextColor3 = Color3.fromRGB(0, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = sg
end

function WorkspaceService:SpawnPortals()
	for _, biome in ipairs(Constants.BIOMES) do
		self:CreatePortal(biome)
	end
end

function WorkspaceService:CreatePortal(biomeData)
	local portal = Instance.new("Part")
	portal.Name = biomeData.Name .. "Portal"
	portal.Size = Vector3.new(8, 12, 2)
	portal.Position = biomeData.Position
	portal.Anchored = true
	portal.Color = biomeData.Color
	portal.Material = Enum.Material.Neon
	portal.Parent = Workspace
	
	-- Add a label
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.Parent = portal
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0.3, 0)
	label.Position = UDim2.new(0, 0, 0.1, 0)
	label.BackgroundTransparency = 1
	label.Text = biomeData.Name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = sg
	
	-- Add description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0.9, 0, 0.2, 0)
	desc.Position = UDim2.new(0.05, 0, 0.5, 0)
	desc.BackgroundTransparency = 1
	desc.Text = biomeData.Description
	desc.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	desc.TextScaled = true
	desc.Font = Enum.Font.Gotham
	desc.Parent = sg
end

function WorkspaceService:CreateTestDummy()
	local dummy = Instance.new("Model")
	dummy.Name = "TestDummy"
	
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 1000
	humanoid.Health = 1000
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	humanoid.Parent = dummy
	
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 5, 2)
	root.Position = Vector3.new(25, 3.5, 25)
	root.Anchored = true
	root.Color = Color3.fromRGB(255, 80, 80)
	root.Parent = dummy
	
	dummy.PrimaryPart = root
	dummy.Parent = Workspace
	
	-- Regen script
	task.spawn(function()
		while true do
			task.wait(3)
			if humanoid.Health < humanoid.MaxHealth then
				humanoid.Health = humanoid.MaxHealth
			end
		end
	end)
end

function WorkspaceService:SetupEnvironment()
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(50, 40, 70)
	lighting.OutdoorAmbient = Color3.fromRGB(30, 20, 50)
	lighting.TimeOfDay = "00:00:00"
end

function WorkspaceService:SpawnSummoningAltar()
	local machine = Instance.new("Part")
	machine.Name = "SummoningAltar"
	machine.Shape = Enum.PartType.Cylinder
	machine.Size = Vector3.new(6, 8, 6)
	machine.Position = Vector3.new(0, 5, -50)
	machine.Anchored = true
	machine.Color = Color3.fromRGB(100, 50, 200)
	machine.Material = Enum.Material.Neon
	machine.Parent = Workspace
	
	-- Rotate cylinder to stand up
	machine.CFrame = CFrame.new(machine.Position) * CFrame.Angles(0, 0, math.rad(90))
	
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Spirit Summon"
	prompt.ActionText = "Summon (100 Essence)"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.Parent = machine
	
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Top -- Top because cylinder is rotated
	sg.Parent = machine
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "SPIRIT\nSUMMON"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = sg
end

return WorkspaceService
