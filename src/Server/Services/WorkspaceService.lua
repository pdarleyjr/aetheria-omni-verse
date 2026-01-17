local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local QuestService = require(script.Parent.QuestService)

-- Atmospheric configuration by zone
local ZONE_ATMOSPHERES = {
	["Hub"] = {
		Density = 0.2,
		Color = Color3.fromRGB(100, 80, 180),
		Haze = 0,
		Glare = 0,
		Offset = 0
	},
	["Glitch Wastes"] = {
		Density = 0.5,
		Color = Color3.fromRGB(150, 50, 200),
		Haze = 2,
		Glare = 0.5,
		Offset = 0.3
	},
	["Azure Sea"] = {
		Density = 0.3,
		Color = Color3.fromRGB(80, 150, 220),
		Haze = 1,
		Glare = 0.2,
		Offset = 0.1
	},
	["Throne of the Glitch King"] = {
		Density = 0.7,
		Color = Color3.fromRGB(200, 0, 100),
		Haze = 5,
		Glare = 1,
		Offset = 0.5
	}
}

-- Difficulty scaling based on distance from Hub
local HUB_CENTER = Vector3.new(0, 0, 0)
local MAX_DIFFICULTY_DISTANCE = 1000

local WorkspaceService = {}

function WorkspaceService:SetupLighting()
	Lighting.ClockTime = 0
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(80, 40, 120) -- Purple

	-- Enhanced Atmosphere with volumetric fog
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "MainAtmosphere"
	atmosphere.Density = 0.3
	atmosphere.Offset = 0
	atmosphere.Color = Color3.fromRGB(80, 40, 120)
	atmosphere.DecayColor = Color3.fromRGB(40, 20, 60)
	atmosphere.Glare = 0
	atmosphere.Haze = 1
	atmosphere.Parent = Lighting
	self.Atmosphere = atmosphere

	-- Bloom for ethereal glow
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "ChaosBloom"
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 0.9
	bloom.Parent = Lighting

	-- Color correction for "Cohesive Chaos" aesthetic
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "ChaosColorCorrection"
	colorCorrection.Brightness = 0.05
	colorCorrection.Contrast = 0.15
	colorCorrection.Saturation = 0.2
	colorCorrection.TintColor = Color3.fromRGB(255, 240, 255)
	colorCorrection.Parent = Lighting
	self.ColorCorrection = colorCorrection

	local sky = Instance.new("Sky")
	sky.Name = "NebulaSky"
	sky.SkyboxBk = "rbxassetid://159454299"
	sky.SkyboxDn = "rbxassetid://159454299"
	sky.SkyboxFt = "rbxassetid://159454299"
	sky.SkyboxLf = "rbxassetid://159454299"
	sky.SkyboxRt = "rbxassetid://159454299"
	sky.SkyboxUp = "rbxassetid://159454299"
	sky.Parent = Lighting
	
	-- Start time-of-day cycle
	self:StartDayNightCycle()
end

function WorkspaceService:StartDayNightCycle()
	-- Slowly cycle time of day
	task.spawn(function()
		while true do
			Lighting.ClockTime = (Lighting.ClockTime + 0.001) % 24
			self:UpdateDustMotesForTimeOfDay()
			task.wait(0.1)
		end
	end)
end

function WorkspaceService:UpdateDustMotesForTimeOfDay()
	local dustEmitters = Workspace:FindFirstChild("DustMotes")
	if not dustEmitters then return end
	
	local time = Lighting.ClockTime
	local isDaytime = time >= 6 and time <= 18
	local brightness = isDaytime and 1 or 0.3
	
	for _, emitter in pairs(dustEmitters:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			emitter.LightEmission = brightness
			emitter.Rate = isDaytime and 15 or 5
		end
	end
end

function WorkspaceService:TeleportToHub(player)
	if not player or not player.Character then return end
	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(0, 5, 0)
	end
end

function WorkspaceService:Init()
	print("[WorkspaceService] Initializing...")
	self:SetupLighting()
end

function WorkspaceService:Start()
	print("[WorkspaceService] Starting...")
	self:GenerateGlitchSpikes()
	self:GenerateDecor()
	self:GenerateHubDecor()
	self:GenerateEnvironmentalParticles()
	self:GenerateAmbientDustMotes()
	self:GenerateZoneSpecificEffects()
	self:SpawnWilds()
	self:SpawnThrone()
	self:SpawnAzureSea()
	self:GeneratePortals()
	self:StartZoneAtmosphereMonitoring()
end

function WorkspaceService:GenerateAmbientDustMotes()
	local dustFolder = Instance.new("Folder")
	dustFolder.Name = "DustMotes"
	dustFolder.Parent = Workspace
	
	-- Create dust emitters at key locations
	local locations = {
		{pos = Vector3.new(0, 10, 0), size = Vector3.new(200, 50, 200), name = "HubDust"},
		{pos = Vector3.new(500, 10, 0), size = Vector3.new(300, 50, 300), name = "GlitchDust"},
		{pos = Vector3.new(0, 10, 2000), size = Vector3.new(500, 50, 500), name = "SeaDust"},
	}
	
	for _, loc in ipairs(locations) do
		local emitterPart = Instance.new("Part")
		emitterPart.Name = loc.name
		emitterPart.Size = loc.size
		emitterPart.Position = loc.pos
		emitterPart.Anchored = true
		emitterPart.CanCollide = false
		emitterPart.Transparency = 1
		emitterPart.Parent = dustFolder
		
		local dustEmitter = Instance.new("ParticleEmitter")
		dustEmitter.Name = "DustParticles"
		dustEmitter.Texture = "rbxassetid://241685484"
		dustEmitter.Color = ColorSequence.new(Color3.fromRGB(200, 180, 255))
		dustEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.5, 0.3),
			NumberSequenceKeypoint.new(1, 0.1)
		})
		dustEmitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.6),
			NumberSequenceKeypoint.new(0.7, 0.6),
			NumberSequenceKeypoint.new(1, 1)
		})
		dustEmitter.Lifetime = NumberRange.new(5, 10)
		dustEmitter.Speed = NumberRange.new(0.2, 1)
		dustEmitter.SpreadAngle = Vector2.new(180, 180)
		dustEmitter.Rate = 10
		dustEmitter.RotSpeed = NumberRange.new(-10, 10)
		dustEmitter.LightEmission = 0.5
		dustEmitter.Parent = emitterPart
	end
	
	print("[WorkspaceService] Generated Ambient Dust Motes")
end

function WorkspaceService:GenerateZoneSpecificEffects()
	local effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "ZoneEffects"
	effectsFolder.Parent = Workspace
	
	-- Glitch distortion effect near Glitch King Throne
	local throneZone = Constants.ZONES["Throne of the Glitch King"]
	if throneZone then
		self:CreateGlitchDistortionEffect(effectsFolder, throneZone.Center)
	end
	
	-- Heat shimmer effect for intense zones (simulated with particles)
	local glitchZone = Constants.ZONES["Glitch Wastes"]
	if glitchZone then
		self:CreateHeatShimmerEffect(effectsFolder, glitchZone.Center)
	end
	
	print("[WorkspaceService] Generated Zone-Specific Effects")
end

function WorkspaceService:CreateGlitchDistortionEffect(parent, center)
	-- Visual glitch distortion using rapidly flickering parts
	local glitchPart = Instance.new("Part")
	glitchPart.Name = "GlitchDistortion"
	glitchPart.Size = Vector3.new(100, 100, 100)
	glitchPart.Position = center
	glitchPart.Anchored = true
	glitchPart.CanCollide = false
	glitchPart.Transparency = 1
	glitchPart.Parent = parent
	
	-- Glitch particles
	local glitchEmitter = Instance.new("ParticleEmitter")
	glitchEmitter.Name = "GlitchParticles"
	glitchEmitter.Texture = "rbxassetid://243660364"
	glitchEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
	})
	glitchEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.1, 2),
		NumberSequenceKeypoint.new(0.2, 0),
		NumberSequenceKeypoint.new(0.3, 3),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 0)
	})
	glitchEmitter.Transparency = NumberSequence.new(0.3, 0.8)
	glitchEmitter.Lifetime = NumberRange.new(0.2, 0.5)
	glitchEmitter.Speed = NumberRange.new(5, 20)
	glitchEmitter.SpreadAngle = Vector2.new(180, 180)
	glitchEmitter.Rate = 50
	glitchEmitter.LightEmission = 1
	glitchEmitter.RotSpeed = NumberRange.new(-500, 500)
	glitchEmitter.Parent = glitchPart
	
	-- Flicker effect
	task.spawn(function()
		while glitchPart.Parent do
			glitchEmitter.Rate = math.random(20, 80)
			glitchEmitter.Speed = NumberRange.new(math.random(3, 10), math.random(15, 30))
			task.wait(0.1 + math.random() * 0.2)
		end
	end)
end

function WorkspaceService:CreateHeatShimmerEffect(parent, center)
	-- Heat shimmer using rising particles
	local shimmerPart = Instance.new("Part")
	shimmerPart.Name = "HeatShimmer"
	shimmerPart.Size = Vector3.new(300, 5, 300)
	shimmerPart.Position = center + Vector3.new(0, 2, 0)
	shimmerPart.Anchored = true
	shimmerPart.CanCollide = false
	shimmerPart.Transparency = 1
	shimmerPart.Parent = parent
	
	local shimmerEmitter = Instance.new("ParticleEmitter")
	shimmerEmitter.Name = "ShimmerParticles"
	shimmerEmitter.Texture = "rbxassetid://241685484"
	shimmerEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 200, 150))
	shimmerEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(0.5, 5),
		NumberSequenceKeypoint.new(1, 3)
	})
	shimmerEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.95),
		NumberSequenceKeypoint.new(0.5, 0.85),
		NumberSequenceKeypoint.new(1, 0.95)
	})
	shimmerEmitter.Lifetime = NumberRange.new(2, 4)
	shimmerEmitter.Speed = NumberRange.new(2, 5)
	shimmerEmitter.SpreadAngle = Vector2.new(10, 10)
	shimmerEmitter.Rate = 30
	shimmerEmitter.Acceleration = Vector3.new(0, 1, 0)
	shimmerEmitter.LightEmission = 0.1
	shimmerEmitter.Parent = shimmerPart
end

function WorkspaceService:StartZoneAtmosphereMonitoring()
	-- Monitor player positions and adjust atmosphere based on zone
	task.spawn(function()
		while true do
			for _, player in pairs(Players:GetPlayers()) do
				local character = player.Character
				if character then
					local root = character:FindFirstChild("HumanoidRootPart")
					if root then
						self:UpdateAtmosphereForPosition(root.Position)
					end
				end
			end
			task.wait(1)
		end
	end)
end

function WorkspaceService:UpdateAtmosphereForPosition(position)
	if not self.Atmosphere then return end
	
	-- Calculate distance from hub for difficulty scaling
	local distanceFromHub = (position - HUB_CENTER).Magnitude
	local difficultyFactor = math.clamp(distanceFromHub / MAX_DIFFICULTY_DISTANCE, 0, 1)
	
	-- Determine current zone
	local currentZone = "Hub"
	for zoneName, zoneData in pairs(Constants.ZONES or {}) do
		if zoneData.Center then
			local zoneDistance = (position - zoneData.Center).Magnitude
			local zoneRadius = zoneData.Size and math.max(zoneData.Size.X, zoneData.Size.Z) / 2 or 500
			if zoneDistance < zoneRadius then
				currentZone = zoneName
				break
			end
		end
	end
	
	-- Get atmosphere settings for zone
	local zoneAtmo = ZONE_ATMOSPHERES[currentZone] or ZONE_ATMOSPHERES["Hub"]
	
	-- Apply difficulty scaling - more intense effects further from hub
	local scaledDensity = zoneAtmo.Density + (difficultyFactor * 0.3)
	local scaledHaze = zoneAtmo.Haze + (difficultyFactor * 2)
	
	-- Tween atmosphere changes for smooth transitions
	TweenService:Create(self.Atmosphere, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Density = scaledDensity,
		Color = zoneAtmo.Color,
		Haze = scaledHaze,
		Glare = zoneAtmo.Glare,
		Offset = zoneAtmo.Offset
	}):Play()
	
	-- Adjust color correction based on difficulty
	if self.ColorCorrection then
		TweenService:Create(self.ColorCorrection, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Contrast = 0.15 + (difficultyFactor * 0.1),
			Saturation = 0.2 - (difficultyFactor * 0.1)
		}):Play()
	end
end

function WorkspaceService:SpawnWilds()
	local wildsFolder = Instance.new("Folder")
	wildsFolder.Name = "WildsDecor"
	wildsFolder.Parent = Workspace

	-- Gate at (0, 5, 100)
	local leftPillar = Instance.new("Part")
	leftPillar.Name = "GatePillarLeft"
	leftPillar.Size = Vector3.new(4, 20, 4)
	leftPillar.Position = Vector3.new(-10, 10, 100)
	leftPillar.Anchored = true
	leftPillar.Color = Color3.new(0, 0, 0)
	leftPillar.Material = Enum.Material.Slate
	leftPillar.Parent = wildsFolder

	local rightPillar = leftPillar:Clone()
	rightPillar.Name = "GatePillarRight"
	rightPillar.Position = Vector3.new(10, 10, 100)
	rightPillar.Parent = wildsFolder
	
	print("[WorkspaceService] Generated Wilds Gate")
end

function WorkspaceService:SpawnThrone()
	local throneFolder = Instance.new("Folder")
	throneFolder.Name = "ThroneDecor"
	throneFolder.Parent = Workspace

	-- Warning Sign at (0, 5, 400)
	local signPost = Instance.new("Part")
	signPost.Name = "WarningSign"
	signPost.Size = Vector3.new(1, 10, 1)
	signPost.Position = Vector3.new(0, 5, 400)
	signPost.Anchored = true
	signPost.Color = Color3.fromRGB(139, 69, 19)
	signPost.Parent = throneFolder

	local signBoard = Instance.new("Part")
	signBoard.Name = "Board"
	signBoard.Size = Vector3.new(8, 4, 1)
	signBoard.Position = Vector3.new(0, 9, 400)
	signBoard.Anchored = true
	signBoard.Color = Color3.fromRGB(200, 0, 0)
	signBoard.Parent = throneFolder
	
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = signBoard
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "DANGER: THRONE AHEAD"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Parent = surfaceGui

	print("[WorkspaceService] Generated Throne Warning")
end

function WorkspaceService:SpawnAzureSea()
	local zone = Constants.ZONES["Azure Sea"]
	if not zone then return end
	
	local seaFolder = Instance.new("Folder")
	seaFolder.Name = "AzureSea"
	seaFolder.Parent = Workspace
	
	-- Massive Water Part
	local water = Instance.new("Part")
	water.Name = "SeaWater"
	water.Size = Vector3.new(2048, 1, 2048)
	water.Position = zone.Center
	water.Anchored = true
	water.CanCollide = false
	water.Material = Enum.Material.Water
	water.Transparency = 0.2
	water.Color = Color3.fromRGB(0, 100, 255)
	water.Parent = seaFolder
	
	-- Spawn 5 Islands
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		local radius = 400
		local x = zone.Center.X + math.cos(angle) * radius
		local z = zone.Center.Z + math.sin(angle) * radius
		
		local island = Instance.new("Part")
		island.Name = "Island" .. i
		island.Size = Vector3.new(100, 5, 100)
		island.Position = Vector3.new(x, 2, z)
		island.Anchored = true
		island.Material = Enum.Material.Sand
		island.Color = Color3.fromRGB(240, 230, 140)
		island.Shape = Enum.PartType.Cylinder
		island.Parent = seaFolder
		
		-- Add some grass on top
		local grass = Instance.new("Part")
		grass.Name = "GrassTop"
		grass.Size = Vector3.new(90, 1, 90)
		grass.Position = Vector3.new(x, 4.6, z)
		grass.Anchored = true
		grass.Material = Enum.Material.Grass
		grass.Color = Color3.fromRGB(75, 150, 50)
		grass.Shape = Enum.PartType.Cylinder
		grass.Parent = island
	end
	
	print("[WorkspaceService] Generated Azure Sea")
end

function WorkspaceService:GenerateHubDecor()
	-- Create a safe zone/hub area at 0,0,0 if it doesn't exist
	local hubFolder = Instance.new("Folder")
	hubFolder.Name = "HubDecor"
	hubFolder.Parent = Workspace
	
	-- Hub Platform (Floor)
	local hubFloor = Instance.new("Part")
	hubFloor.Name = "HubFloor"
	hubFloor.Size = Vector3.new(500, 5, 500)
	hubFloor.Position = Vector3.new(0, -2.5, 0)
	hubFloor.Anchored = true
	hubFloor.Material = Enum.Material.Neon
	hubFloor.Color = Color3.fromRGB(40, 20, 60) -- Dark Purple
	hubFloor.Parent = hubFolder

	-- Spawn Location
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "HubSpawn"
	spawnLocation.Size = Vector3.new(12, 1, 12)
	spawnLocation.Position = Vector3.new(0, 5, 0)
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = false
	spawnLocation.Transparency = 1
	spawnLocation.Duration = 0
	spawnLocation.Parent = hubFolder
	
	-- Visual Spawn Pad
	local spawnPad = Instance.new("Part")
	spawnPad.Name = "SpawnVisual"
	spawnPad.Size = Vector3.new(12, 0.5, 12)
	spawnPad.Position = Vector3.new(0, 4.25, 0)
	spawnPad.Anchored = true
	spawnPad.Material = Enum.Material.Neon
	spawnPad.Color = Color3.fromRGB(100, 200, 255)
	spawnPad.Shape = Enum.PartType.Cylinder
	spawnPad.Parent = hubFolder

	-- Central Plaza
	local plaza = Instance.new("Part")
	plaza.Name = "PlazaFloor"
	plaza.Size = Vector3.new(100, 1, 100)
	plaza.Position = Vector3.new(0, 4, 0)
	plaza.Anchored = true
	plaza.Material = Enum.Material.SmoothPlastic
	plaza.Color = Color3.fromRGB(200, 200, 220)
	plaza.Parent = hubFolder
	
	-- Decorative Pillars
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		local radius = 40
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		
		local pillar = Instance.new("Part")
		pillar.Name = "HubPillar"
		pillar.Size = Vector3.new(4, 20, 4)
		pillar.Position = Vector3.new(x, 14, z)
		pillar.Anchored = true
		pillar.Material = Enum.Material.Marble
		pillar.Color = Color3.fromRGB(240, 240, 255)
		pillar.Parent = hubFolder
		
		-- Glowing top
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(100, 200, 255)
		light.Range = 20
		light.Brightness = 2
		light.Parent = pillar
	end
	
	print("[WorkspaceService] Generated Hub Decor")
end

function WorkspaceService:GeneratePortals()
	local portalsFolder = Instance.new("Folder")
	portalsFolder.Name = "Portals"
	portalsFolder.Parent = Workspace
	
	local glitchZone = Constants.ZONES["Glitch Wastes"]
	if glitchZone then
		-- Hub -> Glitch Wastes (Neon Magenta)
		self:CreatePortal(portalsFolder, "ToGlitchWastes", Vector3.new(0, 5, 45), glitchZone.Center + Vector3.new(0, 5, 0), Color3.fromRGB(255, 0, 255))
		
		-- Glitch Wastes -> Hub (Neon Cyan)
		self:CreatePortal(portalsFolder, "ToHub", glitchZone.Center + Vector3.new(0, 5, 50), Vector3.new(0, 5, 0), Color3.fromRGB(0, 255, 255))
	end
	
	local azureZone = Constants.ZONES["Azure Sea"]
	if azureZone then
		-- Hub -> Azure Sea
		self:CreatePortal(portalsFolder, "ToAzureSea", Vector3.new(20, 2, 20), azureZone.Center + Vector3.new(0, 10, 0), Color3.fromRGB(0, 150, 255), "TRAVEL TO AZURE SEA")
		
		-- Azure Sea -> Hub
		self:CreatePortal(portalsFolder, "ToHubFromSea", azureZone.Center + Vector3.new(0, 10, 0), Vector3.new(0, 5, 0), Color3.fromRGB(100, 200, 255), "RETURN TO HUB")
	end

	-- Hub -> Realm
	self:CreatePortal(portalsFolder, "ToRealm", Vector3.new(-20, 2, 20), Vector3.new(0, 500, 0), Color3.fromRGB(255, 215, 0), "TRAVEL TO REALM")
end

function WorkspaceService:CreatePortal(parent, name, position, targetPos, color, labelText)
	local portal = Instance.new("Part")
	portal.Name = name
	portal.Size = Vector3.new(8, 10, 1)
	portal.Position = position
	portal.Anchored = true
	portal.CanCollide = false
	portal.Material = Enum.Material.Neon
	portal.Color = color
	portal.Parent = parent
	
	-- Particle Emitter
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(color)
	particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
	particles.Texture = "rbxassetid://243098098" -- Generic particle texture
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 20
	particles.Speed = NumberRange.new(2, 5)
	particles.SpreadAngle = Vector2.new(45, 45)
	particles.Parent = portal

	-- Visual Frame
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Size = Vector3.new(10, 12, 2)
	frame.Position = position
	frame.Anchored = true
	frame.CanCollide = true
	frame.Transparency = 0.8
	frame.Color = color
	frame.Parent = portal
	
	-- Label
	if labelText then
		local surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Face = Enum.NormalId.Front
		surfaceGui.Parent = portal
		
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 0.2, 0)
		textLabel.Position = UDim2.new(0, 0, 0.1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = labelText
		textLabel.TextColor3 = Color3.new(1, 1, 1)
		textLabel.TextScaled = true
		textLabel.Font = Enum.Font.GothamBold
		textLabel.Parent = surfaceGui
		
		-- Back label
		local surfaceGuiBack = surfaceGui:Clone()
		surfaceGuiBack.Face = Enum.NormalId.Back
		surfaceGuiBack.Parent = portal
	end
	
	-- Teleport logic
	local debounce = {}
	portal.Touched:Connect(function(hit)
		local char = hit.Parent
		local root = char:FindFirstChild("HumanoidRootPart")
		if root and not debounce[char] then
			debounce[char] = true
			
			-- Teleport effect
			local highlight = Instance.new("Highlight")
			highlight.FillColor = Color3.new(1, 1, 1)
			highlight.OutlineColor = color
			highlight.Parent = char
			
			task.delay(0.5, function()
				if root then
					root.CFrame = CFrame.new(targetPos)
					
					-- Notify QuestService of zone entry
					local player = Players:GetPlayerFromCharacter(char)
					if player then
						if name == "ToAzureSea" then
							QuestService:OnZoneEntered(player, "Azure Sea")
						elseif name == "ToGlitchWastes" then
							QuestService:OnZoneEntered(player, "Glitch Wastes")
						end
					end
				end
				if highlight then highlight:Destroy() end
				debounce[char] = nil
			end)
		end
	end)
end

function WorkspaceService:GenerateDecor()
	local zone = Constants.ZONES["Glitch Wastes"]
	if not zone then return end
	
	local decorFolder = Instance.new("Folder")
	decorFolder.Name = "Decor"
	decorFolder.Parent = Workspace
	
	local center = zone.Center
	local size = zone.Size
	
	-- Generate Low Poly Decor (Cubes and Pyramids)
	for i = 1, 30 do
		local isCube = math.random() > 0.5
		local decorPart = Instance.new("Part")
		decorPart.Name = isCube and "DecorCube" or "DecorPyramid"
		decorPart.Size = Vector3.new(math.random(3, 8), math.random(3, 8), math.random(3, 8))
		decorPart.Anchored = true
		decorPart.CanCollide = true
		decorPart.Color = Color3.fromRGB(math.random(50, 100), math.random(0, 50), math.random(100, 200))
		decorPart.Material = Enum.Material.Plastic -- Low Poly look
		
		if isCube then
			decorPart.Shape = Enum.PartType.Block
		else
			-- Make a pyramid-ish shape using a Wedge or CornerWedge, or just a rotated block for simplicity in "Low Poly" abstract style
			-- Actually, let's use CornerWedge for variety
			decorPart.Shape = Enum.PartType.CornerWedge
		end
		
		local x = center.X + math.random(-size.X/2, size.X/2)
		local z = center.Z + math.random(-size.Z/2, size.Z/2)
		local y = center.Y + math.random(0, 5) -- On ground
		
		decorPart.Position = Vector3.new(x, y + decorPart.Size.Y/2, z)
		decorPart.CFrame = CFrame.new(decorPart.Position) * CFrame.Angles(math.random(), math.random(), math.random())
		
		decorPart.Parent = decorFolder
	end
end

function WorkspaceService:GenerateGlitchSpikes()
	local zone = Constants.ZONES["Glitch Wastes"]
	if not zone then return end
	
	local spikesFolder = Instance.new("Folder")
	spikesFolder.Name = "GlitchSpikes"
	spikesFolder.Parent = Workspace
	
	local center = zone.Center
	local size = zone.Size
	
	-- Generate 20 random spikes
	for i = 1, 20 do
		local spike = Instance.new("Part")
		spike.Name = "GlitchSpike"
		spike.Size = Vector3.new(4, 12, 4)
		spike.Anchored = true
		spike.CanCollide = false
		spike.Color = Color3.fromRGB(255, 0, 0)
		spike.Material = Enum.Material.Neon
		spike.Shape = Enum.PartType.Cylinder
		
		-- Random position within zone
		local x = center.X + math.random(-size.X/2, size.X/2)
		local z = center.Z + math.random(-size.Z/2, size.Z/2)
		spike.Position = Vector3.new(x, center.Y, z)
		
		-- Rotate to look like a spike coming out of ground
		spike.CFrame = CFrame.new(spike.Position) * CFrame.Angles(0, 0, math.rad(90))
		
		spike.Parent = spikesFolder
		
		-- Damage logic
		local debounce = {}
		spike.Touched:Connect(function(hit)
			local char = hit.Parent
			local humanoid = char:FindFirstChild("Humanoid")
			if humanoid and not debounce[char] then
				debounce[char] = true
				humanoid:TakeDamage(15)
				
				-- Visual feedback
				local highlight = Instance.new("Highlight")
				highlight.FillColor = Color3.fromRGB(255, 0, 0)
				highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				highlight.Parent = char
				task.delay(0.2, function() highlight:Destroy() end)
				
				task.delay(1, function()
					debounce[char] = nil
				end)
			end
		end)
	end
	
	print("[WorkspaceService] Generated Glitch Spikes")
end

function WorkspaceService:GenerateEnvironmentalParticles()
	local particlesFolder = Instance.new("Folder")
	particlesFolder.Name = "EnvironmentalParticles"
	particlesFolder.Parent = Workspace
	
	-- Hub Fog
	local hubFog = Instance.new("Part")
	hubFog.Name = "HubFogEmitter"
	hubFog.Size = Vector3.new(200, 1, 200)
	hubFog.Position = Vector3.new(0, 2, 0)
	hubFog.Anchored = true
	hubFog.CanCollide = false
	hubFog.Transparency = 1
	hubFog.Parent = particlesFolder
	
	local fogEmitter = Instance.new("ParticleEmitter")
	fogEmitter.Texture = "rbxassetid://241685484"
	fogEmitter.Color = ColorSequence.new(Color3.fromRGB(150, 100, 200))
	fogEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 15),
		NumberSequenceKeypoint.new(1, 0)
	})
	fogEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.8),
		NumberSequenceKeypoint.new(0.7, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	})
	fogEmitter.Lifetime = NumberRange.new(8, 12)
	fogEmitter.Speed = NumberRange.new(0.5, 2)
	fogEmitter.SpreadAngle = Vector2.new(180, 180)
	fogEmitter.Rate = 5
	fogEmitter.RotSpeed = NumberRange.new(-20, 20)
	fogEmitter.LightEmission = 0.2
	fogEmitter.Parent = hubFog
	
	-- Floating Debris in Glitch Wastes
	local glitchZone = Constants.ZONES["Glitch Wastes"]
	if glitchZone then
		local debrisEmitter = Instance.new("Part")
		debrisEmitter.Name = "GlitchDebrisEmitter"
		debrisEmitter.Size = Vector3.new(500, 1, 500)
		debrisEmitter.Position = glitchZone.Center + Vector3.new(0, 10, 0)
		debrisEmitter.Anchored = true
		debrisEmitter.CanCollide = false
		debrisEmitter.Transparency = 1
		debrisEmitter.Parent = particlesFolder
		
		local debris = Instance.new("ParticleEmitter")
		debris.Texture = "rbxassetid://243660364"
		debris.Color = ColorSequence.new(Color3.fromRGB(255, 0, 100), Color3.fromRGB(100, 0, 255))
		debris.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.5, 0.8),
			NumberSequenceKeypoint.new(1, 0.2)
		})
		debris.Transparency = NumberSequence.new(0.3, 0.8)
		debris.Lifetime = NumberRange.new(5, 10)
		debris.Speed = NumberRange.new(1, 4)
		debris.SpreadAngle = Vector2.new(180, 180)
		debris.Rate = 15
		debris.Drag = 1
		debris.RotSpeed = NumberRange.new(-100, 100)
		debris.LightEmission = 0.5
		debris.Parent = debrisEmitter
	end
	
	-- Magical Sparkles in Azure Sea
	local azureZone = Constants.ZONES["Azure Sea"]
	if azureZone then
		local sparkleEmitter = Instance.new("Part")
		sparkleEmitter.Name = "SeaSparkleEmitter"
		sparkleEmitter.Size = Vector3.new(800, 1, 800)
		sparkleEmitter.Position = azureZone.Center + Vector3.new(0, 5, 0)
		sparkleEmitter.Anchored = true
		sparkleEmitter.CanCollide = false
		sparkleEmitter.Transparency = 1
		sparkleEmitter.Parent = particlesFolder
		
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Texture = "rbxassetid://243098098"
		sparkles.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255), Color3.fromRGB(200, 255, 255))
		sparkles.Size = NumberSequence.new(0.3, 0)
		sparkles.Transparency = NumberSequence.new(0, 1)
		sparkles.Lifetime = NumberRange.new(2, 4)
		sparkles.Speed = NumberRange.new(2, 6)
		sparkles.SpreadAngle = Vector2.new(180, 30)
		sparkles.Rate = 20
		sparkles.LightEmission = 1
		sparkles.Parent = sparkleEmitter
	end
	
	print("[WorkspaceService] Generated Environmental Particles")
end

return WorkspaceService
