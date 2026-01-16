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
	
	-- Play Intro
	self:PlayIntro()
end

function VisualsController:PlayIntro()
	local camera = Workspace.CurrentCamera
	local player = game.Players.LocalPlayer
	
	-- Wait for character
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart")
	
	-- Cinematic Camera Sequence
	camera.CameraType = Enum.CameraType.Scriptable
	
	-- Start high up
	local startCFrame = CFrame.new(rootPart.Position + Vector3.new(0, 100, 100), rootPart.Position)
	camera.CFrame = startCFrame
	
	-- Tween down to player
	local tweenInfo = TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local goal = { CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 10, 20), rootPart.Position) }
	
	local tween = TweenService:Create(camera, tweenInfo, goal)
	tween:Play()
	
	tween.Completed:Connect(function()
		camera.CameraType = Enum.CameraType.Custom
	end)
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
