--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local VisualsController = {}

function VisualsController:Init()
	print("[VisualsController] Initializing...")
end

function VisualsController:Start()
	print("[VisualsController] Starting...")
	
	self:SetupLighting()
	
	local bossAttack = Remotes.GetEvent("BossAttack")
	bossAttack.OnClientEvent:Connect(function(attackName, duration)
		if attackName == "Spike" then
			self:ShakeCamera(duration or 0.5, 1)
		end
	end)
	
	-- Listen for LevelUp
	local LevelUp = Remotes.GetEvent("LevelUp") -- Assuming this exists or will exist
	if LevelUp then
		LevelUp.OnClientEvent:Connect(function()
			self:PlayLevelUpEffect()
		end)
	end
	
	-- Play Intro
	task.delay(1, function()
		self:PlayIntro()
	end)
	
	-- Monitor for Spirit
	local player = game.Players.LocalPlayer
	player.CharacterAdded:Connect(function(char)
		self:OnCharacterAdded(char)
	end)
	if player.Character then
		self:OnCharacterAdded(player.Character)
	end
end

function VisualsController:OnCharacterAdded(char)
	char.ChildAdded:Connect(function(child)
		if child.Name == "ActiveSpirit" then
			self:LinkSpiritToPlayer(char, child)
		end
	end)
	
	local existingSpirit = char:FindFirstChild("ActiveSpirit")
	if existingSpirit then
		self:LinkSpiritToPlayer(char, existingSpirit)
	end
end

function VisualsController:LinkSpiritToPlayer(char, spirit)
	local root = char:WaitForChild("HumanoidRootPart", 5)
	if not root then return end
	
	local att0 = Instance.new("Attachment")
	att0.Name = "SpiritAtt0"
	att0.Position = Vector3.new(0, 0, 0)
	att0.Parent = root
	
	local att1 = Instance.new("Attachment")
	att1.Name = "SpiritAtt1"
	att1.Position = Vector3.new(0, 0, 0)
	att1.Parent = spirit
	
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(spirit.Color)
	beam.FaceCamera = true
	beam.Width0 = 0.2
	beam.Width1 = 0.2
	beam.Texture = "rbxassetid://446111271" -- Simple beam texture
	beam.TextureSpeed = 1
	beam.Transparency = NumberSequence.new(0.5)
	beam.Parent = spirit
end

function VisualsController:PlayBeamAttack(origin, target, color)
	local terrain = Workspace.Terrain
	
	local att0 = Instance.new("Attachment")
	att0.WorldPosition = origin
	att0.Parent = terrain
	
	local att1 = Instance.new("Attachment")
	att1.WorldPosition = target
	att1.Parent = terrain
	
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(color or Color3.new(1, 1, 1))
	beam.Width0 = 0.5
	beam.Width1 = 0.5
	beam.FaceCamera = true
	beam.Texture = "rbxassetid://446111271"
	beam.TextureSpeed = 2
	beam.TextureLength = 1
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Parent = terrain
	
	Debris:AddItem(att0, 0.5)
	Debris:AddItem(att1, 0.5)
	Debris:AddItem(beam, 0.5)
	
	-- Tween width out
	local tween = TweenService:Create(beam, TweenInfo.new(0.5), {Width0 = 0, Width1 = 0})
	tween:Play()
end

function VisualsController:SetupLighting()
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(30, 30, 40)
	lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 60)
	lighting.Brightness = 2
	lighting.ClockTime = 18 -- Sunset/Dusk
	lighting.GlobalShadows = true
	
	-- Add Atmosphere
	if not lighting:FindFirstChild("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.3
		atmosphere.Offset = 0.25
		atmosphere.Color = Color3.fromRGB(199, 170, 199)
		atmosphere.Decay = Color3.fromRGB(106, 90, 106)
		atmosphere.Glare = 0
		atmosphere.Haze = 1
		atmosphere.Parent = lighting
	end
	
	-- Add Bloom
	if not lighting:FindFirstChild("Bloom") then
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "Bloom"
		bloom.Intensity = 0.4
		bloom.Size = 24
		bloom.Threshold = 0.8
		bloom.Parent = lighting
	end
	
	-- Add SunRays
	if not lighting:FindFirstChild("SunRays") then
		local sunrays = Instance.new("SunRaysEffect")
		sunrays.Name = "SunRays"
		sunrays.Intensity = 0.05
		sunrays.Parent = lighting
	end
end

function VisualsController:PlayIntro()
	local camera = Workspace.CurrentCamera
	local player = game.Players.LocalPlayer
	
	-- Wait for character safely
	local character = player.Character
	if not character then
		character = player.CharacterAdded:Wait()
	end
	
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if not rootPart then return end -- Avoid hang if root part doesn't load
	
	-- Cinematic Camera Sequence
	camera.CameraType = Enum.CameraType.Scriptable
	
	-- Start high up and far away
	local startCFrame = CFrame.new(rootPart.Position + Vector3.new(100, 150, 100), rootPart.Position)
	camera.CFrame = startCFrame
	
	-- Blur effect
	local blur = Instance.new("BlurEffect")
	blur.Size = 24
	blur.Parent = camera
	
	-- Tween 1: Pan around
	local tweenInfo1 = TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local goal1 = { CFrame = CFrame.new(rootPart.Position + Vector3.new(-50, 80, 50), rootPart.Position) }
	local tween1 = TweenService:Create(camera, tweenInfo1, goal1)
	
	-- Tween 2: Zoom in
	local tweenInfo2 = TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal2 = { CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 10, 15), Vector3.new(0, 5, 0)) }
	local tween2 = TweenService:Create(camera, tweenInfo2, goal2)
	
	tween1:Play()
	
	-- Story Text Sequence
	task.delay(1, function()
		-- Ideally call UIController to show subtitles
		-- For now, we'll just use the WelcomeText at the end
	end)
	
	tween1.Completed:Connect(function()
		tween2:Play()
		-- Fade out blur
		TweenService:Create(blur, TweenInfo.new(4, Enum.EasingStyle.Linear), {Size = 0}):Play()
	end)
	
	tween2.Completed:Connect(function()
		camera.CameraType = Enum.CameraType.Custom
		blur:Destroy()
		
		-- Welcome Text
		self:ShowWelcomeText()
	end)
end

function VisualsController:ShowWelcomeText()
	local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IntroGui"
	screenGui.Parent = playerGui
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 100)
	label.Position = UDim2.new(0, 0, 0.4, 0)
	label.BackgroundTransparency = 1
	label.Text = "WELCOME TO THE HUB. DEFEAT THE GLITCH."
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 48
	label.TextTransparency = 1
	label.Parent = screenGui
	
	local t1 = TweenService:Create(label, TweenInfo.new(1), {TextTransparency = 0})
	t1:Play()
	
	t1.Completed:Connect(function()
		task.wait(2)
		local t2 = TweenService:Create(label, TweenInfo.new(1), {TextTransparency = 1})
		t2:Play()
		t2.Completed:Connect(function()
			screenGui:Destroy()
		end)
	end)
end

function VisualsController:PlayLevelUpEffect()
	local player = game.Players.LocalPlayer
	local char = player.Character
	if not char then return end
	
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local part = Instance.new("Part")
	part.Size = Vector3.new(5, 1, 5)
	part.CFrame = root.CFrame * CFrame.new(0, -2, 0)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 215, 0)
	part.Transparency = 0.5
	part.Shape = Enum.PartType.Cylinder
	part.Parent = Workspace
	
	local tween = TweenService:Create(part, TweenInfo.new(1), {
		Size = Vector3.new(5, 20, 5),
		Transparency = 1,
		CFrame = root.CFrame * CFrame.new(0, 10, 0)
	})
	tween:Play()
	Debris:AddItem(part, 1)
end

function VisualsController:ShakeCamera(duration, intensity)
	local camera = Workspace.CurrentCamera
	local startTime = os.clock()
	
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed >= duration then
			connection:Disconnect()
			return
		end
		
		local offset = Vector3.new(
			math.random() - 0.5,
			math.random() - 0.5,
			math.random() - 0.5
		) * intensity * (1 - elapsed/duration)
		
		camera.CFrame = camera.CFrame * CFrame.new(offset)
	end)
end

function VisualsController:PlayHitEffect(position: Vector3, color: Color3?)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = color or Color3.fromRGB(255, 255, 255)
	part.Transparency = 0.2
	part.Shape = Enum.PartType.Ball
	part.Parent = Workspace
	
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {
		Size = Vector3.new(3, 3, 3),
		Transparency = 1
	}
	
	local tween = TweenService:Create(part, tweenInfo, goal)
	tween:Play()
	
	Debris:AddItem(part, 0.3)
end

function VisualsController:PlayAttackEffect(origin: Vector3, target: Vector3, color: Color3?)
	local distance = (target - origin).Magnitude
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.5, 0.5, distance)
	part.CFrame = CFrame.lookAt(origin, target) * CFrame.new(0, 0, -distance/2)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = color or Color3.fromRGB(255, 255, 100)
	part.Parent = Workspace
	
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {
		Size = Vector3.new(0, 0, distance),
		Transparency = 1
	}
	
	local tween = TweenService:Create(part, tweenInfo, goal)
	tween:Play()
	
	Debris:AddItem(part, 0.2)
end

return VisualsController
