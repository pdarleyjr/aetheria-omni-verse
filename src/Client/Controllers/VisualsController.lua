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
end

function VisualsController:PlayIntro()
	local camera = Workspace.CurrentCamera
	local player = game.Players.LocalPlayer
	
	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart")
	
	-- Cinematic Camera Sequence
	camera.CameraType = Enum.CameraType.Scriptable
	
	-- Start high up and far away
	local startCFrame = CFrame.new(rootPart.Position + Vector3.new(0, 200, 200), rootPart.Position)
	camera.CFrame = startCFrame
	
	-- Blur effect
	local blur = Instance.new("BlurEffect")
	blur.Size = 24
	blur.Parent = camera
	
	-- Tween down to player
	local tweenInfo = TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local goal = { CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 10, 20), rootPart.Position) }
	
	local tween = TweenService:Create(camera, tweenInfo, goal)
	tween:Play()
	
	-- Fade out blur
	TweenService:Create(blur, TweenInfo.new(5, Enum.EasingStyle.Linear), {Size = 0}):Play()
	
	tween.Completed:Connect(function()
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
	label.Text = "WELCOME TO THE REALM"
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
