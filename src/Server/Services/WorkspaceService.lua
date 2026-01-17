local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local QuestService = require(script.Parent.QuestService)

local WorkspaceService = {}

function WorkspaceService:SetupLighting()
	Lighting.ClockTime = 0
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(80, 40, 120) -- Purple

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0
	atmosphere.Color = Color3.fromRGB(80, 40, 120)
	atmosphere.Glare = 0
	atmosphere.Haze = 0
	atmosphere.Parent = Lighting

	local sky = Instance.new("Sky")
	sky.Name = "NebulaSky"
	sky.SkyboxBk = "rbxassetid://159454299"
	sky.SkyboxDn = "rbxassetid://159454299"
	sky.SkyboxFt = "rbxassetid://159454299"
	sky.SkyboxLf = "rbxassetid://159454299"
	sky.SkyboxRt = "rbxassetid://159454299"
	sky.SkyboxUp = "rbxassetid://159454299"
	sky.Parent = Lighting
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
	self:SpawnWilds()
	self:SpawnThrone()
	self:SpawnAzureSea()
	self:GeneratePortals()
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
		-- Hub -> Glitch Wastes
		self:CreatePortal(portalsFolder, "ToGlitchWastes", Vector3.new(0, 5, 45), glitchZone.Center + Vector3.new(0, 5, 0), Color3.fromRGB(255, 0, 255))
		
		-- Glitch Wastes -> Hub
		self:CreatePortal(portalsFolder, "ToHub", glitchZone.Center + Vector3.new(0, 5, 50), Vector3.new(0, 5, 0), Color3.fromRGB(100, 200, 255))
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
	
	-- Generate some floating crystals
	for i = 1, 15 do
		local crystal = Instance.new("Part")
		crystal.Name = "FloatingCrystal"
		crystal.Size = Vector3.new(2, 4, 2)
		crystal.Anchored = true
		crystal.CanCollide = false
		crystal.Color = Color3.fromRGB(100, 200, 255)
		crystal.Material = Enum.Material.Neon
		crystal.Shape = Enum.PartType.Cylinder
		
		local x = center.X + math.random(-size.X/2, size.X/2)
		local z = center.Z + math.random(-size.Z/2, size.Z/2)
		local y = center.Y + math.random(10, 30)
		
		crystal.Position = Vector3.new(x, y, z)
		crystal.CFrame = CFrame.new(crystal.Position) * CFrame.Angles(math.random(), math.random(), math.random())
		
		crystal.Parent = decorFolder
		
		-- Simple floating animation
		task.spawn(function()
			local startY = y
			while crystal.Parent do
				local t = os.clock()
				crystal.Position = Vector3.new(x, startY + math.sin(t) * 2, z)
				crystal.CFrame = crystal.CFrame * CFrame.Angles(0, 0.01, 0)
				task.wait(0.03)
			end
		end)
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

return WorkspaceService
