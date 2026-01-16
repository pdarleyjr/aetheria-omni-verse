local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

local WorkspaceService = {}

function WorkspaceService:Init()
	print("[WorkspaceService] Initializing...")
	self:SetupLighting()
end

function WorkspaceService:Start()
	print("[WorkspaceService] Starting...")
	self:GenerateGlitchSpikes()
	self:GenerateDecor()
	self:GenerateHubDecor()
end

function WorkspaceService:SetupLighting()
	Lighting.Ambient = Color3.fromRGB(50, 50, 70)
	Lighting.OutdoorAmbient = Color3.fromRGB(30, 30, 50)
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
	Lighting.ShadowSoftness = 0.2
	Lighting.GlobalShadows = true
	
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(150, 150, 200)
	atmosphere.Decay = Color3.fromRGB(100, 100, 150)
	atmosphere.Glare = 0.5
	atmosphere.Haze = 1
	atmosphere.Parent = Lighting
	
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.4
	bloom.Size = 24
	bloom.Threshold = 0.8
	bloom.Parent = Lighting
	
	local blur = Instance.new("BlurEffect")
	blur.Size = 2
	blur.Parent = Lighting
	
	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.1
	sunRays.Spread = 0.8
	sunRays.Parent = Lighting
end

function WorkspaceService:GenerateHubDecor()
	-- Create a safe zone/hub area at 0,0,0 if it doesn't exist
	local hubFolder = Instance.new("Folder")
	hubFolder.Name = "HubDecor"
	hubFolder.Parent = Workspace
	
	-- Central Plaza
	local plaza = Instance.new("Part")
	plaza.Name = "PlazaFloor"
	plaza.Size = Vector3.new(100, 1, 100)
	plaza.Position = Vector3.new(0, 0, 0)
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
		pillar.Position = Vector3.new(x, 10, z)
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
