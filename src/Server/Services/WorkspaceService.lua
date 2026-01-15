--!strict
--[[
	WorkspaceService.lua
	Creates and manages the immersive 3D game world for Aetheria: The Omni-Verse
	
	Features:
	- Massive Central Hub (Aetheria Nexus) - 300 stud circular platform
	- Seven Elemental Realm Portals (Fire, Water, Earth, Air, Light, Shadow, Glitch)
	- Combat Arena Zone with training dummies and PvP colosseum
	- Spirit Sanctuary for spirit care and display
	- Social Plaza with leaderboards and gathering areas
	- NPC interaction stations
	- Sophisticated environmental effects and lighting
]]

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- Only run on server
if not RunService:IsServer() then
	error("WorkspaceService can only be required on the server")
end

-- Service
local WorkspaceService = {}

-- Constants
local HUB_RADIUS = 150
local HUB_HEIGHT = 8
local OBELISK_HEIGHT = 60
local PORTAL_DISTANCE = 120
local ARENA_DISTANCE = 250

--====================================
-- HELPER FUNCTIONS (Reusable Factories)
--====================================

-- Create a decorative pillar
local function createPillar(position: Vector3, height: number, radius: number, material: Enum.Material, color: Color3, parent: Instance): Part
	local pillar = Instance.new("Part")
	pillar.Name = "Pillar"
	pillar.Shape = Enum.PartType.Cylinder
	pillar.Size = Vector3.new(height, radius * 2, radius * 2)
	pillar.Position = position
	pillar.Orientation = Vector3.new(0, 0, 90)
	pillar.Anchored = true
	pillar.Material = material
	pillar.Color = color
	pillar.CanCollide = false
	pillar.Parent = parent
	return pillar
end

-- Create glowing crystal
local function createCrystal(position: Vector3, size: Vector3, color: Color3, parent: Instance): Part
	local crystal = Instance.new("Part")
	crystal.Name = "Crystal"
	crystal.Size = size
	crystal.Position = position
	crystal.Anchored = true
	crystal.Material = Enum.Material.Neon
	crystal.Color = color
	crystal.CanCollide = false
	crystal.Parent = parent
	
	-- Add glow
	local pointLight = Instance.new("PointLight")
	pointLight.Color = color
	pointLight.Brightness = 3
	pointLight.Range = 25
	pointLight.Parent = crystal
	
	-- Floating animation
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = TweenService:Create(crystal, tweenInfo, {
		Position = position + Vector3.new(0, 2, 0),
		Orientation = crystal.Orientation + Vector3.new(0, 180, 0)
	})
	tween:Play()
	
	return crystal
end

-- Create particle emitter
local function createParticleEmitter(parent: Instance, color: ColorSequence, rate: number, lifetime: NumberRange): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = color
	emitter.Rate = rate
	emitter.Lifetime = lifetime
	emitter.Speed = NumberRange.new(2, 5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 2)
	})
	emitter.LightEmission = 1
	emitter.Parent = parent
	return emitter
end

-- Create arch structure
local function createArch(position: Vector3, rotation: number, width: number, height: number, color: Color3, parent: Instance): Model
	local archModel = Instance.new("Model")
	archModel.Name = "Arch"
	
	-- Left pillar
	local leftPillar = Instance.new("Part")
	leftPillar.Size = Vector3.new(3, height, 3)
	leftPillar.Position = position + Vector3.new(-width/2, height/2, 0)
	leftPillar.Anchored = true
	leftPillar.Material = Enum.Material.Marble
	leftPillar.Color = color
	leftPillar.Parent = archModel
	
	-- Right pillar
	local rightPillar = Instance.new("Part")
	rightPillar.Size = Vector3.new(3, height, 3)
	rightPillar.Position = position + Vector3.new(width/2, height/2, 0)
	rightPillar.Anchored = true
	rightPillar.Material = Enum.Material.Marble
	rightPillar.Color = color
	rightPillar.Parent = archModel
	
	-- Top arc
	local topArc = Instance.new("Part")
	topArc.Size = Vector3.new(width, 3, 4)
	topArc.Position = position + Vector3.new(0, height + 1.5, 0)
	topArc.Anchored = true
	topArc.Material = Enum.Material.Marble
	topArc.Color = color
	topArc.Parent = archModel
	
	archModel.Parent = parent
	archModel:SetPrimaryPartCFrame(CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0))
	
	return archModel
end

--====================================
-- MAIN HUB (Aetheria Nexus)
--====================================

local function createCentralHub(): Model
	print("Creating Aetheria Nexus (Central Hub)...")
	
	local hubModel = Instance.new("Model")
	hubModel.Name = "AetheriaNexus"
	
	-- Main circular platform (multi-tiered)
	for tier = 1, 3 do
		local tierRadius = HUB_RADIUS - (tier - 1) * 30
		local tierHeight = HUB_HEIGHT - (tier - 1) * 2
		local tierY = (tier - 1) * 3
		
		local platform = Instance.new("Part")
		platform.Name = `MainPlatform_Tier{tier}`
		platform.Shape = Enum.PartType.Cylinder
		platform.Size = Vector3.new(tierHeight, tierRadius * 2, tierRadius * 2)
		platform.Position = Vector3.new(0, tierY, 0)
		platform.Orientation = Vector3.new(0, 0, 90)
		platform.Anchored = true
		platform.Material = tier == 1 and Enum.Material.Marble or Enum.Material.Cobblestone
		platform.Color = tier == 1 and Color3.fromRGB(220, 220, 230) or Color3.fromRGB(180, 180, 190)
		platform.TopSurface = Enum.SurfaceType.Smooth
		platform.Parent = hubModel
		
		-- Add decorative pattern
		if tier == 1 then
			for i = 1, 12 do
				local angle = (i / 12) * math.pi * 2
				local x = math.cos(angle) * (tierRadius - 10)
				local z = math.sin(angle) * (tierRadius - 10)
				
				local decoration = Instance.new("Part")
				decoration.Size = Vector3.new(5, tierHeight + 0.5, 5)
				decoration.Position = Vector3.new(x, tierY, z)
				decoration.Anchored = true
				decoration.Material = Enum.Material.Granite
				decoration.Color = Color3.fromRGB(138, 43, 226) -- Purple
				decoration.CanCollide = false
				decoration.Parent = hubModel
			end
		end
	end
	
	-- Connecting stairs between tiers
	for tier = 1, 2 do
		local startRadius = HUB_RADIUS - (tier - 1) * 30
		local tierY = (tier - 1) * 3
		
		for i = 1, 4 do
			local angle = ((i - 1) / 4) * math.pi * 2 + math.pi / 4
			local x = math.cos(angle) * (startRadius - 25)
			local z = math.sin(angle) * (startRadius - 25)
			
			for step = 1, 6 do
				local stair = Instance.new("Part")
				stair.Size = Vector3.new(12, 1, 8)
				stair.Position = Vector3.new(x, tierY + step * 0.5, z)
				stair.Anchored = true
				stair.Material = Enum.Material.Slate
				stair.Color = Color3.fromRGB(150, 150, 160)
				stair.Orientation = Vector3.new(0, math.deg(angle), 0)
				stair.Parent = hubModel
			end
		end
	end
	
	-- Central Obelisk
	local obeliskBase = Instance.new("Part")
	obeliskBase.Name = "ObeliskBase"
	obeliskBase.Size = Vector3.new(12, OBELISK_HEIGHT, 12)
	obeliskBase.Position = Vector3.new(0, OBELISK_HEIGHT / 2 + 6, 0)
	obeliskBase.Anchored = true
	obeliskBase.Material = Enum.Material.Marble
	obeliskBase.Color = Color3.fromRGB(100, 100, 120)
	obeliskBase.Parent = hubModel
	
	-- Obelisk crystal top
	local crystalTop = Instance.new("Part")
	crystalTop.Name = "ObeliskCrystal"
	crystalTop.Size = Vector3.new(8, 15, 8)
	crystalTop.Position = Vector3.new(0, OBELISK_HEIGHT + 13.5, 0)
	crystalTop.Anchored = true
	crystalTop.Material = Enum.Material.Neon
	crystalTop.Color = Color3.fromRGB(138, 43, 226)
	crystalTop.CanCollide = false
	crystalTop.Parent = hubModel
	
	-- Obelisk glow
	local obeliskGlow = Instance.new("PointLight")
	obeliskGlow.Color = Color3.fromRGB(138, 43, 226)
	obeliskGlow.Brightness = 5
	obeliskGlow.Range = 100
	obeliskGlow.Parent = crystalTop
	
	-- Obelisk particles
	createParticleEmitter(
		crystalTop,
		ColorSequence.new(Color3.fromRGB(138, 43, 226)),
		20,
		NumberRange.new(3, 5)
	)
	
	-- Rotation animation
	local rotateInfo = TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
	local rotateTween = TweenService:Create(crystalTop, rotateInfo, {
		Orientation = crystalTop.Orientation + Vector3.new(0, 360, 0)
	})
	rotateTween:Play()
	
	-- Decorative pillars around obelisk
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local distance = 25
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance
		
		createPillar(
			Vector3.new(x, 18, z),
			30,
			2,
			Enum.Material.Marble,
			Color3.fromRGB(180, 180, 200),
			hubModel
		)
		
		-- Small crystal on each pillar
		createCrystal(
			Vector3.new(x, 35, z),
			Vector3.new(2, 4, 2),
			Color3.fromRGB(138, 43, 226),
			hubModel
		)
	end
	
	-- Spawn location
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "MainSpawn"
	spawnLocation.Size = Vector3.new(15, 1, 15)
	spawnLocation.Position = Vector3.new(0, 7, 0)
	spawnLocation.Anchored = true
	spawnLocation.BrickColor = BrickColor.new("Lime green")
	spawnLocation.Material = Enum.Material.Neon
	spawnLocation.Transparency = 0.5
	spawnLocation.CanCollide = false
	spawnLocation.Duration = 0
	spawnLocation.Parent = hubModel
	
	-- Floating essence particles around hub
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local x = math.cos(angle) * 80
		local z = math.sin(angle) * 80
		
		local particleAnchor = Instance.new("Part")
		particleAnchor.Size = Vector3.new(1, 1, 1)
		particleAnchor.Position = Vector3.new(x, 15, z)
		particleAnchor.Transparency = 1
		particleAnchor.Anchored = true
		particleAnchor.CanCollide = false
		particleAnchor.Parent = hubModel
		
		createParticleEmitter(
			particleAnchor,
			ColorSequence.new(Color3.fromRGB(200, 150, 255)),
			5,
			NumberRange.new(4, 6)
		)
	end
	
	hubModel.Parent = workspace
	print("✓ Central Hub created")
	return hubModel
end

--====================================
-- SEVEN ELEMENTAL REALM PORTALS
--====================================

local function createRealmPortals(): ()
	print("Creating Seven Elemental Realm Portals...")
	
	local realms = {
		{
			Name = "Infernus",
			DisplayName = "Fire Realm: Infernus",
			Color = Color3.fromRGB(255, 80, 0),
			SecondaryColor = Color3.fromRGB(255, 200, 0),
			Angle = 0,
			Description = "Volcanic wastelands of eternal flame",
			ParticleTexture = "rbxasset://textures/particles/fire_main.dds",
		},
		{
			Name = "AzureDepths",
			DisplayName = "Water Realm: Azure Depths",
			Color = Color3.fromRGB(0, 150, 255),
			SecondaryColor = Color3.fromRGB(100, 200, 255),
			Angle = 51.4,
			Description = "Mystical underwater kingdom",
			ParticleTexture = "rbxasset://textures/particles/smoke_main.dds",
		},
		{
			Name = "TerraSanctum",
			DisplayName = "Earth Realm: Terra Sanctum",
			Color = Color3.fromRGB(80, 180, 50),
			SecondaryColor = Color3.fromRGB(150, 120, 70),
			Angle = 102.8,
			Description = "Ancient forests and crystal caverns",
			ParticleTexture = "rbxasset://textures/particles/sparkles_main.dds",
		},
		{
			Name = "ZephyrHeights",
			DisplayName = "Air Realm: Zephyr Heights",
			Color = Color3.fromRGB(200, 240, 255),
			SecondaryColor = Color3.fromRGB(255, 255, 255),
			Angle = 154.2,
			Description = "Floating islands in endless sky",
			ParticleTexture = "rbxasset://textures/particles/smoke_main.dds",
		},
		{
			Name = "Celestia",
			DisplayName = "Light Realm: Celestia",
			Color = Color3.fromRGB(255, 240, 150),
			SecondaryColor = Color3.fromRGB(255, 255, 255),
			Angle = 205.6,
			Description = "Divine realm of holy radiance",
			ParticleTexture = "rbxasset://textures/particles/sparkles_main.dds",
		},
		{
			Name = "UmbraVoid",
			DisplayName = "Shadow Realm: Umbra Void",
			Color = Color3.fromRGB(100, 0, 150),
			SecondaryColor = Color3.fromRGB(50, 0, 80),
			Angle = 257,
			Description = "Mysterious darkness and void energy",
			ParticleTexture = "rbxasset://textures/particles/smoke_main.dds",
		},
		{
			Name = "ChaoticNexus",
			DisplayName = "Glitch Realm: Chaotic Nexus",
			Color = Color3.fromRGB(255, 0, 255),
			SecondaryColor = Color3.fromRGB(0, 255, 255),
			Angle = 308.4,
			Description = "Brainrot memes and chaotic physics",
			ParticleTexture = "rbxasset://textures/particles/sparkles_main.dds",
		},
	}
	
	for _, realm in realms do
		local angle = math.rad(realm.Angle)
		local x = math.cos(angle) * PORTAL_DISTANCE
		local z = math.sin(angle) * PORTAL_DISTANCE
		local position = Vector3.new(x, 5, z)
		
		local portalModel = Instance.new("Model")
		portalModel.Name = `{realm.Name}Portal`
		
		-- Portal frame
		createArch(position, realm.Angle, 20, 25, realm.Color, portalModel)
		
		-- Portal gateway (the actual portal surface)
		local gateway = Instance.new("Part")
		gateway.Name = "Gateway"
		gateway.Size = Vector3.new(18, 23, 1)
		gateway.Position = position + Vector3.new(0, 13.5, 0)
		gateway.Anchored = true
		gateway.Material = Enum.Material.Neon
		gateway.Color = realm.Color
		gateway.Transparency = 0.3
		gateway.CanCollide = false
		gateway.Parent = portalModel
		
		-- Portal swirl effect
		local swirl = Instance.new("ParticleEmitter")
		swirl.Texture = realm.ParticleTexture
		swirl.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, realm.Color),
			ColorSequenceKeypoint.new(0.5, realm.SecondaryColor),
			ColorSequenceKeypoint.new(1, realm.Color)
		})
		swirl.Rate = 50
		swirl.Lifetime = NumberRange.new(2, 3)
		swirl.Speed = NumberRange.new(5, 10)
		swirl.Rotation = NumberRange.new(0, 360)
		swirl.RotSpeed = NumberRange.new(-100, 100)
		swirl.SpreadAngle = Vector2.new(30, 30)
		swirl.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0)
		})
		swirl.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1)
		})
		swirl.LightEmission = 1
		swirl.Parent = gateway
		
		-- Portal glow
		local portalLight = Instance.new("PointLight")
		portalLight.Color = realm.Color
		portalLight.Brightness = 4
		portalLight.Range = 50
		portalLight.Parent = gateway
		
		-- Base platform
		local platform = Instance.new("Part")
		platform.Shape = Enum.PartType.Cylinder
		platform.Size = Vector3.new(3, 30, 30)
		platform.Position = position - Vector3.new(0, 1.5, 0)
		platform.Orientation = Vector3.new(0, 0, 90)
		platform.Anchored = true
		platform.Material = Enum.Material.Marble
		platform.Color = realm.SecondaryColor
		platform.Parent = portalModel
		
		-- Floating crystals around portal
		for i = 1, 4 do
			local crystalAngle = (i / 4) * math.pi * 2
			local crystalDist = 15
			local cx = x + math.cos(crystalAngle) * crystalDist
			local cz = z + math.sin(crystalAngle) * crystalDist
			
			createCrystal(
				Vector3.new(cx, 20, cz),
				Vector3.new(2, 6, 2),
				realm.Color,
				portalModel
			)
		end
		
		-- Proximity prompt for interaction
		local proximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.ActionText = `Enter {realm.Name}`
		proximityPrompt.ObjectText = realm.DisplayName
		proximityPrompt.MaxActivationDistance = 15
		proximityPrompt.RequiresLineOfSight = false
		proximityPrompt.Parent = gateway
		
		-- Info sign
		local signPart = Instance.new("Part")
		signPart.Size = Vector3.new(12, 6, 1)
		signPart.Position = position + Vector3.new(0, 2, -12)
		signPart.Anchored = true
		signPart.Material = Enum.Material.SmoothPlastic
		signPart.Color = Color3.fromRGB(40, 40, 50)
		signPart.Parent = portalModel
		
		local signGui = Instance.new("SurfaceGui")
		signGui.Face = Enum.NormalId.Front
		signGui.Parent = signPart
		
		local signText = Instance.new("TextLabel")
		signText.Size = UDim2.new(1, 0, 1, 0)
		signText.BackgroundTransparency = 1
		signText.Text = `{realm.DisplayName}\n\n{realm.Description}`
		signText.TextColor3 = realm.Color
		signText.TextSize = 24
		signText.Font = Enum.Font.GothamBold
		signText.TextScaled = true
		signText.TextWrapped = true
		signText.Parent = signGui
		
		-- Pulse animation
		local pulseInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local pulseTween = TweenService:Create(gateway, pulseInfo, {
			Transparency = 0.6
		})
		pulseTween:Play()
		
		portalModel.Parent = workspace
	end
	
	print("✓ Realm portals created")
end

--====================================
-- COMBAT ARENA ZONE
--====================================

local function createCombatArena(): ()
	print("Creating Combat Arena Zone...")
	
	local arenaModel = Instance.new("Model")
	arenaModel.Name = "CombatArena"
	
	local arenaX = ARENA_DISTANCE
	local arenaZ = 0
	
	-- Main arena floor (colosseum style)
	local arenaFloor = Instance.new("Part")
	arenaFloor.Shape = Enum.PartType.Cylinder
	arenaFloor.Size = Vector3.new(5, 150, 150)
	arenaFloor.Position = Vector3.new(arenaX, 2.5, arenaZ)
	arenaFloor.Orientation = Vector3.new(0, 0, 90)
	arenaFloor.Anchored = true
	arenaFloor.Material = Enum.Material.Slate
	arenaFloor.Color = Color3.fromRGB(120, 100, 80)
	arenaFloor.Parent = arenaModel
	
	-- Arena boundary walls
	for i = 1, 16 do
		local angle = (i / 16) * math.pi * 2
		local wallX = arenaX + math.cos(angle) * 78
		local wallZ = arenaZ + math.sin(angle) * 78
		
		local wall = Instance.new("Part")
		wall.Size = Vector3.new(12, 15, 4)
		wall.Position = Vector3.new(wallX, 12.5, wallZ)
		wall.Orientation = Vector3.new(0, math.deg(angle) + 90, 0)
		wall.Anchored = true
		wall.Material = Enum.Material.Brick
		wall.Color = Color3.fromRGB(140, 120, 100)
		wall.Parent = arenaModel
		
		-- Decorative torch on wall
		local torch = Instance.new("Part")
		torch.Size = Vector3.new(2, 4, 2)
		torch.Position = Vector3.new(wallX, 22, wallZ)
		torch.Anchored = true
		torch.Material = Enum.Material.Neon
		torch.Color = Color3.fromRGB(255, 150, 0)
		torch.Shape = Enum.PartType.Ball
		torch.CanCollide = false
		torch.Parent = arenaModel
		
		local torchLight = Instance.new("PointLight")
		torchLight.Color = Color3.fromRGB(255, 150, 0)
		torchLight.Brightness = 3
		torchLight.Range = 30
		torchLight.Parent = torch
	end
	
	-- Spectator seating (tiered rings)
	for tier = 1, 3 do
		local seatRadius = 85 + (tier * 12)
		local seatHeight = 5 + (tier * 8)
		
		for i = 1, 20 do
			local angle = (i / 20) * math.pi * 2
			local seatX = arenaX + math.cos(angle) * seatRadius
			local seatZ = arenaZ + math.sin(angle) * seatRadius
			
			local seat = Instance.new("Part")
			seat.Size = Vector3.new(10, 4, 6)
			seat.Position = Vector3.new(seatX, seatHeight, seatZ)
			seat.Orientation = Vector3.new(0, math.deg(angle) + 180, 0)
			seat.Anchored = true
			seat.Material = Enum.Material.Wood
			seat.Color = Color3.fromRGB(100, 70, 50)
			seat.Parent = arenaModel
		end
	end
	
	-- Training dummies with varied HP
	local dummyConfigs = {
		{HP = 500, Color = Color3.fromRGB(100, 255, 100), Pos = Vector3.new(arenaX + 40, 7.5, arenaZ)},
		{HP = 1000, Color = Color3.fromRGB(255, 255, 100), Pos = Vector3.new(arenaX + 40, 7.5, arenaZ + 15)},
		{HP = 2000, Color = Color3.fromRGB(255, 150, 100), Pos = Vector3.new(arenaX + 40, 7.5, arenaZ - 15)},
		{HP = 5000, Color = Color3.fromRGB(255, 50, 50), Pos = Vector3.new(arenaX + 40, 7.5, arenaZ + 30)},
	}
	
	for _, config in dummyConfigs do
		local dummyModel = Instance.new("Model")
		dummyModel.Name = `TrainingDummy_{config.HP}HP`
		
		-- Torso
		local torso = Instance.new("Part")
		torso.Name = "Torso"
		torso.Size = Vector3.new(4, 6, 2)
		torso.Position = config.Pos
		torso.Anchored = true
		torso.Color = config.Color
		torso.Material = Enum.Material.Plastic
		torso.Parent = dummyModel
		
		-- Head
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(3, 3, 3)
		head.Position = config.Pos + Vector3.new(0, 5, 0)
		head.Anchored = true
		head.Color = config.Color
		head.Material = Enum.Material.Plastic
		head.Parent = dummyModel
		
		-- Humanoid
		local humanoid = Instance.new("Humanoid")
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.MaxHealth = config.HP
		humanoid.Health = config.HP
		humanoid.WalkSpeed = 0
		humanoid.Parent = dummyModel
		
		-- Health display
		local healthGui = Instance.new("BillboardGui")
		healthGui.Size = UDim2.new(5, 0, 2, 0)
		healthGui.StudsOffset = Vector3.new(0, 4, 0)
		healthGui.AlwaysOnTop = true
		healthGui.Parent = head
		
		local healthBar = Instance.new("Frame")
		healthBar.Name = "Bar"
		healthBar.Size = UDim2.new(1, 0, 0.2, 0)
		healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		healthBar.BorderSizePixel = 0
		healthBar.Parent = healthGui
		
		local healthText = Instance.new("TextLabel")
		healthText.Name = "Text"
		healthText.Size = UDim2.new(1, 0, 0.8, 0)
		healthText.Position = UDim2.new(0, 0, 0.2, 0)
		healthText.BackgroundTransparency = 1
		healthText.Text = `Training Dummy\n{config.HP} / {config.HP} HP`
		healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
		healthText.TextScaled = true
		healthText.Font = Enum.Font.GothamBold
		healthText.Parent = healthGui
		
		-- Regeneration
		humanoid.HealthChanged:Connect(function(health)
			healthText.Text = `Training Dummy\n{math.floor(health)} / {config.HP} HP`
			healthBar.Size = UDim2.new(health / config.HP, 0, 0.2, 0)
			
			task.delay(3, function()
				if humanoid then
					humanoid.Health = config.HP
				end
			end)
		end)
		
		dummyModel.Parent = arenaModel
	end
	
	-- Arena sign
	local arenaSign = Instance.new("Part")
	arenaSign.Size = Vector3.new(30, 15, 2)
	arenaSign.Position = Vector3.new(arenaX, 35, arenaZ - 85)
	arenaSign.Anchored = true
	arenaSign.Material = Enum.Material.SmoothPlastic
	arenaSign.Color = Color3.fromRGB(40, 40, 50)
	arenaSign.Parent = arenaModel
	
	local arenaGui = Instance.new("SurfaceGui")
	arenaGui.Face = Enum.NormalId.Front
	arenaGui.Parent = arenaSign
	
	local arenaText = Instance.new("TextLabel")
	arenaText.Size = UDim2.new(1, 0, 1, 0)
	arenaText.BackgroundTransparency = 1
	arenaText.Text = "⚔️ COMBAT ARENA ⚔️\n\nTest Your Skills!\nPvP • Training • Duels"
	arenaText.TextColor3 = Color3.fromRGB(255, 215, 0)
	arenaText.TextSize = 36
	arenaText.Font = Enum.Font.GothamBold
	arenaText.TextScaled = true
	arenaText.Parent = arenaGui
	
	arenaModel.Parent = workspace
	print("✓ Combat Arena created")
end

--====================================
-- SPIRIT SANCTUARY
--====================================

local function createSpiritSanctuary(): ()
	print("Creating Spirit Sanctuary...")
	
	local sanctuaryModel = Instance.new("Model")
	sanctuaryModel.Name = "SpiritSanctuary"
	
	local sanctX = -ARENA_DISTANCE
	local sanctZ = 0
	
	-- Main sanctuary platform
	local platform = Instance.new("Part")
	platform.Shape = Enum.PartType.Cylinder
	platform.Size = Vector3.new(5, 120, 120)
	platform.Position = Vector3.new(sanctX, 2.5, sanctZ)
	platform.Orientation = Vector3.new(0, 0, 90)
	platform.Anchored = true
	platform.Material = Enum.Material.Grass
	platform.Color = Color3.fromRGB(100, 200, 100)
	platform.Parent = sanctuaryModel
	
	-- Display pedestals for spirits
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local pedX = sanctX + math.cos(angle) * 35
		local pedZ = sanctZ + math.sin(angle) * 35
		
		-- Pedestal
		local pedestal = Instance.new("Part")
		pedestal.Shape = Enum.PartType.Cylinder
		pedestal.Size = Vector3.new(8, 8, 8)
		pedestal.Position = Vector3.new(pedX, 9, pedZ)
		pedestal.Orientation = Vector3.new(0, 0, 90)
		pedestal.Anchored = true
		pedestal.Material = Enum.Material.Marble
		pedestal.Color = Color3.fromRGB(220, 220, 255)
		pedestal.Parent = sanctuaryModel
		
		-- Display crystal
		local displayCrystal = Instance.new("Part")
		displayCrystal.Shape = Enum.PartType.Ball
		displayCrystal.Size = Vector3.new(5, 5, 5)
		displayCrystal.Position = Vector3.new(pedX, 14, pedZ)
		displayCrystal.Anchored = true
		displayCrystal.Material = Enum.Material.Glass
		displayCrystal.Transparency = 0.5
		displayCrystal.Color = Color3.fromRGB(150, 200, 255)
		displayCrystal.CanCollide = false
		displayCrystal.Parent = sanctuaryModel
		
		-- Glow effect
		local displayLight = Instance.new("PointLight")
		displayLight.Color = Color3.fromRGB(150, 200, 255)
		displayLight.Brightness = 2
		displayLight.Range = 20
		displayLight.Parent = displayCrystal
		
		-- ProximityPrompt
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "View Spirit"
		prompt.ObjectText = `Spirit Display #{i}`
		prompt.MaxActivationDistance = 10
		prompt.Parent = displayCrystal
	end
	
	-- Central breeding station
	local breedingStation = Instance.new("Part")
	breedingStation.Shape = Enum.PartType.Cylinder
	breedingStation.Size = Vector3.new(8, 25, 25)
	breedingStation.Position = Vector3.new(sanctX, 9, sanctZ)
	breedingStation.Orientation = Vector3.new(0, 0, 90)
	breedingStation.Anchored = true
	breedingStation.Material = Enum.Material.Neon
	breedingStation.Color = Color3.fromRGB(255, 150, 255)
	breedingStation.Transparency = 0.3
	breedingStation.Parent = sanctuaryModel
	
	local breedPrompt = Instance.new("ProximityPrompt")
	breedPrompt.ActionText = "Breed Spirits"
	breedPrompt.ObjectText = "Spirit Breeding Station"
	breedPrompt.MaxActivationDistance = 15
	breedPrompt.Parent = breedingStation
	
	-- Ambient nature particles
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local partX = sanctX + math.cos(angle) * 50
		local partZ = sanctZ + math.sin(angle) * 50
		
		local particleAnchor = Instance.new("Part")
		particleAnchor.Size = Vector3.new(1, 1, 1)
		particleAnchor.Position = Vector3.new(partX, 10, partZ)
		particleAnchor.Transparency = 1
		particleAnchor.Anchored = true
		particleAnchor.CanCollide = false
		particleAnchor.Parent = sanctuaryModel
		
		createParticleEmitter(
			particleAnchor,
			ColorSequence.new(Color3.fromRGB(100, 255, 150)),
			3,
			NumberRange.new(5, 8)
		)
	end
	
	-- Sanctuary sign
	local sanctSign = Instance.new("Part")
	sanctSign.Size = Vector3.new(25, 12, 2)
	sanctSign.Position = Vector3.new(sanctX, 30, sanctZ - 65)
	sanctSign.Anchored = true
	sanctSign.Material = Enum.Material.SmoothPlastic
	sanctSign.Color = Color3.fromRGB(40, 40, 50)
	sanctSign.Parent = sanctuaryModel
	
	local sanctGui = Instance.new("SurfaceGui")
	sanctGui.Face = Enum.NormalId.Front
	sanctGui.Parent = sanctSign
	
	local sanctText = Instance.new("TextLabel")
	sanctText.Size = UDim2.new(1, 0, 1, 0)
	sanctText.BackgroundTransparency = 1
	sanctText.Text = "🌟 SPIRIT SANCTUARY 🌟\n\nCare • Breed • Display\nYour Spirit Companions"
	sanctText.TextColor3 = Color3.fromRGB(150, 255, 150)
	sanctText.TextSize = 32
	sanctText.Font = Enum.Font.GothamBold
	sanctText.TextScaled = true
	sanctText.Parent = sanctGui
	
	sanctuaryModel.Parent = workspace
	print("✓ Spirit Sanctuary created")
end

--====================================
-- SOCIAL PLAZA
--====================================

local function createSocialPlaza(): ()
	print("Creating Social Plaza...")
	
	local plazaModel = Instance.new("Model")
	plazaModel.Name = "SocialPlaza"
	
	local plazaX = 0
	local plazaZ = ARENA_DISTANCE
	
	-- Main plaza floor
	local plazaFloor = Instance.new("Part")
	plazaFloor.Size = Vector3.new(100, 3, 100)
	plazaFloor.Position = Vector3.new(plazaX, 1.5, plazaZ)
	plazaFloor.Anchored = true
	plazaFloor.Material = Enum.Material.Brick
	plazaFloor.Color = Color3.fromRGB(180, 160, 140)
	plazaFloor.Parent = plazaModel
	
	-- Benches and social areas
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local benchX = plazaX + math.cos(angle) * 30
		local benchZ = plazaZ + math.sin(angle) * 30
		
		-- Bench
		local bench = Instance.new("Part")
		bench.Size = Vector3.new(10, 2, 4)
		bench.Position = Vector3.new(benchX, 4, benchZ)
		bench.Orientation = Vector3.new(0, math.deg(angle) + 90, 0)
		bench.Anchored = true
		bench.Material = Enum.Material.Wood
		bench.Color = Color3.fromRGB(120, 80, 50)
		bench.Parent = plazaModel
		
		-- Seat
		local seat = Instance.new("Seat")
		seat.Size = Vector3.new(10, 1, 4)
		seat.Position = Vector3.new(benchX, 5, benchZ)
		seat.Orientation = Vector3.new(0, math.deg(angle) + 90, 0)
		seat.Anchored = true
		seat.Material = Enum.Material.Wood
		seat.Color = Color3.fromRGB(140, 100, 60)
		seat.Parent = plazaModel
	end
	
	-- Leaderboard monuments
	local leaderboardPositions = {
		{Name = "Combat Masters", Pos = Vector3.new(plazaX - 35, 15, plazaZ + 35), Color = Color3.fromRGB(255, 100, 100)},
		{Name = "Top Summoners", Pos = Vector3.new(plazaX + 35, 15, plazaZ + 35), Color = Color3.fromRGB(100, 255, 100)},
		{Name = "Realm Explorers", Pos = Vector3.new(plazaX, 15, plazaZ - 35), Color = Color3.fromRGB(100, 200, 255)},
	}
	
	for _, board in leaderboardPositions do
		-- Monument base
		local base = Instance.new("Part")
		base.Size = Vector3.new(18, 25, 3)
		base.Position = board.Pos
		base.Anchored = true
		base.Material = Enum.Material.Marble
		base.Color = Color3.fromRGB(200, 200, 210)
		base.Parent = plazaModel
		
		-- Display screen
		local screen = Instance.new("Part")
		screen.Size = Vector3.new(16, 20, 1)
		screen.Position = board.Pos + Vector3.new(0, 0, 2)
		screen.Anchored = true
		screen.Material = Enum.Material.Neon
		screen.Color = board.Color
		screen.CanCollide = false
		screen.Parent = plazaModel
		
		local screenGui = Instance.new("SurfaceGui")
		screenGui.Face = Enum.NormalId.Front
		screenGui.Parent = screen
		
		local screenText = Instance.new("TextLabel")
		screenText.Size = UDim2.new(1, 0, 1, 0)
		screenText.BackgroundTransparency = 1
		screenText.Text = `🏆 {board.Name} 🏆\n\n1. Player Name - 9999\n2. Player Name - 8888\n3. Player Name - 7777\n4. Player Name - 6666\n5. Player Name - 5555`
		screenText.TextColor3 = Color3.fromRGB(255, 255, 255)
		screenText.TextSize = 20
		screenText.Font = Enum.Font.GothamBold
		screenText.TextScaled = true
		screenText.TextXAlignment = Enum.TextXAlignment.Left
		screenText.Parent = screenGui
	end
	
	-- Guild recruitment board
	local guildBoard = Instance.new("Part")
	guildBoard.Size = Vector3.new(20, 15, 2)
	guildBoard.Position = Vector3.new(plazaX - 35, 10, plazaZ - 35)
	guildBoard.Anchored = true
	guildBoard.Material = Enum.Material.Wood
	guildBoard.Color = Color3.fromRGB(80, 60, 40)
	guildBoard.Parent = plazaModel
	
	local guildGui = Instance.new("SurfaceGui")
	guildGui.Face = Enum.NormalId.Front
	guildGui.Parent = guildBoard
	
	local guildText = Instance.new("TextLabel")
	guildText.Size = UDim2.new(1, 0, 1, 0)
	guildText.BackgroundTransparency = 1
	guildText.Text = "📜 GUILD RECRUITMENT 📜\n\n• Shadow Warriors\n• Light Seekers\n• Spirit Guardians\n• Chaos Legion"
	guildText.TextColor3 = Color3.fromRGB(255, 220, 150)
	guildText.TextSize = 24
	guildText.Font = Enum.Font.Gotham
	guildText.TextScaled = true
	guildText.TextXAlignment = Enum.TextXAlignment.Left
	guildText.Parent = guildGui
	
	local guildPrompt = Instance.new("ProximityPrompt")
	guildPrompt.ActionText = "Browse Guilds"
	guildPrompt.ObjectText = "Guild Board"
	guildPrompt.MaxActivationDistance = 10
	guildPrompt.Parent = guildBoard
	
	-- Trading post area
	local tradingPost = Instance.new("Part")
	tradingPost.Shape = Enum.PartType.Cylinder
	tradingPost.Size = Vector3.new(6, 15, 15)
	tradingPost.Position = Vector3.new(plazaX + 35, 8, plazaZ - 35)
	tradingPost.Orientation = Vector3.new(0, 0, 90)
	tradingPost.Anchored = true
	tradingPost.Material = Enum.Material.Wood
	tradingPost.Color = Color3.fromRGB(100, 70, 40)
	tradingPost.Parent = plazaModel
	
	local tradePrompt = Instance.new("ProximityPrompt")
	tradePrompt.ActionText = "Open Trading"
	tradePrompt.ObjectText = "Trading Post"
	tradePrompt.MaxActivationDistance = 12
	tradePrompt.Parent = tradingPost
	
	-- Central fountain
	local fountain = Instance.new("Part")
	fountain.Shape = Enum.PartType.Cylinder
	fountain.Size = Vector3.new(4, 20, 20)
	fountain.Position = Vector3.new(plazaX, 7, plazaZ)
	fountain.Orientation = Vector3.new(0, 0, 90)
	fountain.Anchored = true
	fountain.Material = Enum.Material.Marble
	fountain.Color = Color3.fromRGB(200, 220, 255)
	fountain.Parent = plazaModel
	
	-- Fountain water
	local water = Instance.new("Part")
	water.Shape = Enum.PartType.Cylinder
	water.Size = Vector3.new(3, 18, 18)
	water.Position = Vector3.new(plazaX, 6.5, plazaZ)
	water.Orientation = Vector3.new(0, 0, 90)
	water.Anchored = true
	water.Material = Enum.Material.Glass
	water.Color = Color3.fromRGB(100, 150, 255)
	water.Transparency = 0.5
	water.CanCollide = false
	water.Parent = plazaModel
	
	createParticleEmitter(
		water,
		ColorSequence.new(Color3.fromRGB(150, 200, 255)),
		15,
		NumberRange.new(2, 4)
	)
	
	plazaModel.Parent = workspace
	print("✓ Social Plaza created")
end

--====================================
-- NPC STATIONS
--====================================

local function createNPCStations(): ()
	print("Creating NPC Stations...")
	
	local npcModel = Instance.new("Model")
	npcModel.Name = "NPCStations"
	
	local npcLocations = {
		{
			Name = "Spirit Merchant",
			Position = Vector3.new(-40, 10, -40),
			Color = Color3.fromRGB(255, 200, 100),
			Icon = "💰",
		},
		{
			Name = "Realm Master",
			Position = Vector3.new(40, 10, -40),
			Color = Color3.fromRGB(150, 100, 255),
			Icon = "🌌",
		},
		{
			Name = "Combat Trainer",
			Position = Vector3.new(-40, 10, 40),
			Color = Color3.fromRGB(255, 100, 100),
			Icon = "⚔️",
		},
		{
			Name = "Quest Giver",
			Position = Vector3.new(40, 10, 40),
			Color = Color3.fromRGB(100, 255, 200),
			Icon = "📜",
		},
	}
	
	for _, npc in npcLocations do
		-- Platform
		local platform = Instance.new("Part")
		platform.Shape = Enum.PartType.Cylinder
		platform.Size = Vector3.new(3, 20, 20)
		platform.Position = npc.Position
		platform.Orientation = Vector3.new(0, 0, 90)
		platform.Anchored = true
		platform.Material = Enum.Material.Marble
		platform.Color = npc.Color
		platform.Parent = npcModel
		
		-- Hologram display
		local hologram = Instance.new("Part")
		hologram.Size = Vector3.new(4, 6, 0.5)
		hologram.Position = npc.Position + Vector3.new(0, 5, 0)
		hologram.Anchored = true
		hologram.Material = Enum.Material.Neon
		hologram.Color = npc.Color
		hologram.Transparency = 0.3
		hologram.CanCollide = false
		hologram.Parent = npcModel
		
		local holoGui = Instance.new("SurfaceGui")
		holoGui.Face = Enum.NormalId.Front
		holoGui.AlwaysOnTop = true
		holoGui.Parent = hologram
		
		local holoText = Instance.new("TextLabel")
		holoText.Size = UDim2.new(1, 0, 1, 0)
		holoText.BackgroundTransparency = 1
		holoText.Text = `{npc.Icon}\n{npc.Name}`
		holoText.TextColor3 = Color3.fromRGB(255, 255, 255)
		holoText.TextSize = 32
		holoText.Font = Enum.Font.GothamBold
		holoText.TextScaled = true
		holoText.Parent = holoGui
		
		-- Proximity prompt
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = `Talk to {npc.Name}`
		prompt.ObjectText = npc.Name
		prompt.MaxActivationDistance = 15
		prompt.Parent = hologram
		
		-- Glow aura
		local auraLight = Instance.new("PointLight")
		auraLight.Color = npc.Color
		auraLight.Brightness = 3
		auraLight.Range = 35
		auraLight.Parent = platform
		
		-- Particle effects
		createParticleEmitter(
			hologram,
			ColorSequence.new(npc.Color),
			8,
			NumberRange.new(2, 4)
		)
		
		-- Floating animation
		local floatInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local floatTween = TweenService:Create(hologram, floatInfo, {
			Position = npc.Position + Vector3.new(0, 7, 0)
		})
		floatTween:Play()
	end
	
	npcModel.Parent = workspace
	print("✓ NPC Stations created")
end

--====================================
-- ENVIRONMENT SETUP
--====================================

local function setupEnvironment(): ()
	print("Setting up immersive environment...")
	
	-- Custom skybox (starry void with nebulas)
	local sky = Instance.new("Sky")
	sky.SkyboxBk = "rbxassetid://159454299"
	sky.SkyboxDn = "rbxassetid://159454296"
	sky.SkyboxFt = "rbxassetid://159454293"
	sky.SkyboxLf = "rbxassetid://159454286"
	sky.SkyboxRt = "rbxassetid://159454300"
	sky.SkyboxUp = "rbxassetid://159454288"
	sky.MoonAngularSize = 15
	sky.StarCount = 8000
	sky.Parent = Lighting
	
	-- Atmosphere for depth and god rays
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.4
	atmosphere.Offset = 0.3
	atmosphere.Color = Color3.fromRGB(180, 150, 220) -- Purple mystical tint
	atmosphere.Decay = Color3.fromRGB(80, 50, 120)
	atmosphere.Glare = 0.4
	atmosphere.Haze = 2
	atmosphere.Parent = Lighting
	
	-- Lighting settings for dramatic effect
	Lighting.Ambient = Color3.fromRGB(60, 50, 80)
	Lighting.Brightness = 2.5
	Lighting.ColorShift_Top = Color3.fromRGB(138, 43, 226) -- Purple
	Lighting.ColorShift_Bottom = Color3.fromRGB(60, 30, 90)
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 60, 90)
	Lighting.ClockTime = 20 -- Evening/twilight
	Lighting.GeographicLatitude = 0
	Lighting.ExposureCompensation = 0.2
	
	-- Bloom for magical glow
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 32
	bloom.Threshold = 0.7
	bloom.Parent = Lighting
	
	-- Sun rays (god rays)
	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.15
	sunRays.Spread = 0.1
	sunRays.Parent = Lighting
	
	-- Color correction for vibrant MMORPG aesthetic
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Brightness = 0.1
	colorCorrection.Contrast = 0.15
	colorCorrection.Saturation = 0.3
	colorCorrection.TintColor = Color3.fromRGB(255, 250, 255)
	colorCorrection.Parent = Lighting
	
	-- Depth of field for cinematic feel
	local depthOfField = Instance.new("DepthOfFieldEffect")
	depthOfField.FarIntensity = 0.05
	depthOfField.FocusDistance = 50
	depthOfField.InFocusRadius = 30
	depthOfField.NearIntensity = 0.1
	depthOfField.Parent = Lighting
	
	print("✓ Environment setup complete")
end

--====================================
-- SERVICE INITIALIZATION
--====================================

function WorkspaceService:Init(): ()
	print("Initializing WorkspaceService...")
	print("WorkspaceService initialized - Ready to create Aetheria")
end

function WorkspaceService:Start(): ()
	print("Starting WorkspaceService...")
	print("Building the world of Aetheria: The Omni-Verse...")
	
	-- Clear default baseplate
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
		print("✓ Removed default baseplate")
	end
	
	-- Build the world sequentially
	setupEnvironment()
	createCentralHub()
	createRealmPortals()
	createCombatArena()
	createSpiritSanctuary()
	createSocialPlaza()
	createNPCStations()
	
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("✨ AETHERIA: THE OMNI-VERSE ✨")
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("🏰 Central Hub: Aetheria Nexus - COMPLETE")
	print("🌀 Seven Realm Portals - COMPLETE")
	print("⚔️  Combat Arena Zone - COMPLETE")
	print("🌟 Spirit Sanctuary - COMPLETE")
	print("👥 Social Plaza - COMPLETE")
	print("💬 NPC Stations - COMPLETE")
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("WorkspaceService started - Immersive world ready!")
end

return WorkspaceService
