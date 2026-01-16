--!strict
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Random = Random.new()

local WorkspaceService = {}

function WorkspaceService:Init()
	print("[WorkspaceService] Init")
	
	-- Initialize Remotes
	self.TeleportToHubRemote = Remotes.GetEvent("TeleportToHub")
	self.TeleportToHubRemote.OnServerEvent:Connect(function(player)
		self:TeleportToHub(player)
	end)
end

function WorkspaceService:Start()
	print("[WorkspaceService] Start")
	self:CreateSpawnHub()
	self:SpawnPortals()
	self:CreateTestDummy()
	self:SetupEnvironment()
	self:SpawnSummoningAltar()
	self:SpawnGlitchBiome()
end

function WorkspaceService:TeleportToHub(player)
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			-- Check if already teleporting to prevent spam
			if not character:GetAttribute("Teleporting") then
				character:SetAttribute("Teleporting", true)
				rootPart.CFrame = CFrame.new(0, 5, 0)
				task.wait(1)
				character:SetAttribute("Teleporting", nil)
			end
		end
	end
end

function WorkspaceService:CreateSpawnHub()
	local folder = Workspace:FindFirstChild("SpawnHub") or Instance.new("Folder")
	folder.Name = "SpawnHub"
	folder.Parent = Workspace

	local spawnLocation = folder:FindFirstChild("SpawnLocation")
	if not spawnLocation then
		local part = Instance.new("Part")
		part.Name = "SpawnLocation"
		part.Size = Vector3.new(150, 1, 150)
		part.Position = Vector3.new(0, 0, 0)
		part.Anchored = true
		part.Material = Enum.Material.SmoothPlastic
		part.Color = Color3.fromRGB(50, 50, 60)
		part.Parent = folder
		
		local spawn = Instance.new("SpawnLocation")
		spawn.Size = Vector3.new(12, 1, 12)
		spawn.Position = Vector3.new(0, 1, 0)
		spawn.Anchored = true
		spawn.Transparency = 1
		spawn.CanCollide = false
		spawn.Parent = folder
	end
	
	-- Welcome Sign
	local sign = Instance.new("Part")
	sign.Name = "WelcomeSign"
	sign.Size = Vector3.new(20, 10, 1)
	sign.Position = Vector3.new(0, 10, -60)
	sign.Anchored = true
	sign.Color = Color3.fromRGB(20, 20, 20)
	sign.Parent = folder
	
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
	local folder = Workspace:FindFirstChild("Portals") or Instance.new("Folder")
	folder.Name = "Portals"
	folder.Parent = Workspace

	for _, biome in ipairs(Constants.BIOMES) do
		self:CreatePortal(biome, folder)
	end
end

function WorkspaceService:CreatePortal(biomeData, parent)
	local portal = Instance.new("Part")
	portal.Name = biomeData.Name .. "Portal"
	portal.Size = Vector3.new(8, 12, 2)
	portal.Position = biomeData.Position
	portal.Anchored = true
	portal.Color = biomeData.Color
	portal.Material = Enum.Material.Neon
	portal.Parent = parent
	
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

	-- Teleport Logic
	portal.Touched:Connect(function(hit)
		local character = hit.Parent
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChild("Humanoid")
		
		if rootPart and humanoid then
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				local zone = Constants.ZONES[biomeData.Name]
				if zone then
					if not character:GetAttribute("Teleporting") then
						character:SetAttribute("Teleporting", true)
						-- Teleport slightly above center
						rootPart.CFrame = CFrame.new(zone.Center + Vector3.new(0, 15, 0))
						task.wait(2)
						character:SetAttribute("Teleporting", nil)
					end
				end
			end
		end
	end)
end

function WorkspaceService:SpawnGlitchBiome()
	local zoneData = Constants.ZONES["Glitch Wastes"]
	if not zoneData then return end

	local folder = Instance.new("Folder")
	folder.Name = "GlitchWastes"
	folder.Parent = Workspace

	-- Base Platform
	local base = Instance.new("Part")
	base.Name = "BasePlatform"
	base.Size = zoneData.Size
	base.Position = zoneData.Center
	base.Anchored = true
	base.Material = Enum.Material.Foil
	base.Color = zoneData.PlatformColor
	base.Parent = folder

	-- Generate Glitch Structures
	for i = 1, 50 do
		local part = Instance.new("Part")
		part.Name = "GlitchPart"
		part.Size = Vector3.new(Random:NextNumber(5, 20), Random:NextNumber(5, 50), Random:NextNumber(5, 20))

		local offset = Vector3.new(
			Random:NextNumber(-zoneData.Size.X/2, zoneData.Size.X/2),
			Random:NextNumber(0, 50),
			Random:NextNumber(-zoneData.Size.Z/2, zoneData.Size.Z/2)
		)
		part.Position = zoneData.Center + Vector3.new(0, zoneData.Size.Y/2, 0) + offset
		part.Anchored = true
		part.Material = Enum.Material.Neon
		-- Purple/Pink/Magenta hues
		part.Color = Color3.fromHSV(Random:NextNumber(0.75, 0.9), 1, 1)
		part.Orientation = Vector3.new(Random:NextNumber(0, 360), Random:NextNumber(0, 360), Random:NextNumber(0, 360))
		part.Parent = folder
	end
	
	-- Return Portal
	local returnPortal = Instance.new("Part")
	returnPortal.Name = "ReturnPortal"
	returnPortal.Size = Vector3.new(8, 12, 2)
	returnPortal.Position = zoneData.Center + Vector3.new(0, 10, 0)
	returnPortal.Anchored = true
	returnPortal.Color = Color3.fromRGB(255, 255, 255)
	returnPortal.Material = Enum.Material.Neon
	returnPortal.Parent = folder
	
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.Parent = returnPortal
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "RETURN TO HUB"
	label.TextColor3 = Color3.new(0, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = sg
	
	returnPortal.Touched:Connect(function(hit)
		local character = hit.Parent
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart and character:FindFirstChild("Humanoid") then
			if not character:GetAttribute("Teleporting") then
				character:SetAttribute("Teleporting", true)
				rootPart.CFrame = CFrame.new(0, 5, 0) -- Back to spawn
				task.wait(2)
				character:SetAttribute("Teleporting", nil)
			end
		end
	end)
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
	lighting.Brightness = 2
	lighting.ShadowSoftness = 0.2
	lighting.GlobalShadows = true
	
	-- Atmosphere
	local atmosphere = lighting:FindFirstChild("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(100, 80, 150)
	atmosphere.Decay = Color3.fromRGB(50, 40, 70)
	atmosphere.Glare = 0.5
	atmosphere.Haze = 1
	atmosphere.Parent = lighting
	
	-- Sky
	local sky = lighting:FindFirstChild("Sky") or Instance.new("Sky")
	sky.SkyboxBk = "rbxassetid://7018684000" -- Placeholder skybox IDs
	sky.SkyboxDn = "rbxassetid://7018684000"
	sky.SkyboxFt = "rbxassetid://7018684000"
	sky.SkyboxLf = "rbxassetid://7018684000"
	sky.SkyboxRt = "rbxassetid://7018684000"
	sky.SkyboxUp = "rbxassetid://7018684000"
	sky.SunTextureId = "rbxassetid://6196665106"
	sky.Parent = lighting
	
	-- Bloom
	local bloom = lighting:FindFirstChild("Bloom") or Instance.new("BloomEffect")
	bloom.Intensity = 0.4
	bloom.Size = 24
	bloom.Threshold = 0.8
	bloom.Parent = lighting
	
	-- ColorCorrection
	local cc = lighting:FindFirstChild("ColorCorrection") or Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.05
	cc.Contrast = 0.1
	cc.Saturation = 0.2
	cc.Parent = lighting
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
