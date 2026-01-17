--[[
	ParticleController.lua
	Environmental particle system manager for ambient visual effects
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maid = require(Shared.Modules.Maid)
local Remotes = require(Shared.Remotes)

local ParticleController = {}
ParticleController._maid = nil
ParticleController._activeEmitters = {}
ParticleController._zoneMaid = nil
ParticleController._weaponTrails = {}

function ParticleController:Init()
	print("[ParticleController] Initializing...")
	self._maid = Maid.new()
	self._zoneMaid = Maid.new()
	self._activeEmitters = {}
	self._weaponTrails = {}
	
	-- Listen for combat events
	local ShowDamage = Remotes.GetEvent("ShowDamage")
	ShowDamage.OnClientEvent:Connect(function(position, damage, isCritical)
		self:SpawnDamageNumber(position, damage, isCritical)
	end)
	
	local OnCombatHit = Remotes.GetEvent("OnCombatHit")
	OnCombatHit.OnClientEvent:Connect(function(hitPosition, hitType)
		self:SpawnHitEffect(hitPosition, hitType)
		self:DoScreenShake(hitType == "critical" and 0.4 or 0.2)
	end)
	
	local OnEnemyDeath = Remotes.GetEvent("OnEnemyDeath")
	OnEnemyDeath.OnClientEvent:Connect(function(position)
		self:SpawnDeathEffect(position)
		self:DoScreenShake(0.3)
	end)
end

function ParticleController:Start()
	print("[ParticleController] Starting...")
	
	local player = Players.LocalPlayer
	
	-- Cleanup on character respawn
	self._maid:GiveTask(player.CharacterAdded:Connect(function()
		self:CleanupZoneEffects()
		task.delay(1, function()
			self:SpawnAmbientDust()
		end)
	end))
	
	-- Cleanup when player leaves
	self._maid:GiveTask(Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == player then
			self:Destroy()
		end
	end))
	
	-- Initial ambient dust
	if player.Character then
		self:SpawnAmbientDust()
	end
end

function ParticleController:SpawnFogEmitter(position)
	local part = Instance.new("Part")
	part.Name = "FogEmitter"
	part.Size = Vector3.new(20, 1, 20)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = Workspace
	
	local fog = Instance.new("ParticleEmitter")
	fog.Name = "GroundFog"
	fog.Texture = "rbxassetid://243660364" -- Soft cloud texture
	fog.Color = ColorSequence.new(Color3.fromRGB(200, 200, 220))
	fog.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, 8),
		NumberSequenceKeypoint.new(1, 12)
	})
	fog.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.7),
		NumberSequenceKeypoint.new(0.7, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	fog.Lifetime = NumberRange.new(8, 12)
	fog.Rate = 3
	fog.Speed = NumberRange.new(0.5, 1.5)
	fog.SpreadAngle = Vector2.new(180, 0)
	fog.Rotation = NumberRange.new(0, 360)
	fog.RotSpeed = NumberRange.new(-10, 10)
	fog.EmissionDirection = Enum.NormalId.Top
	fog.Parent = part
	
	table.insert(self._activeEmitters, part)
	self._zoneMaid:GiveTask(part)
	
	return part
end

function ParticleController:SpawnFloatingDebris(region)
	-- region = {Center = Vector3, Size = Vector3}
	local center = region.Center or Vector3.new(0, 10, 0)
	local size = region.Size or Vector3.new(50, 20, 50)
	
	local part = Instance.new("Part")
	part.Name = "DebrisEmitter"
	part.Size = size
	part.Position = center
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = Workspace
	
	local debris = Instance.new("ParticleEmitter")
	debris.Name = "FloatingDebris"
	debris.Texture = "rbxassetid://304846479" -- Small particle
	debris.Color = ColorSequence.new(Color3.fromRGB(150, 140, 130))
	debris.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 0.1)
	})
	debris.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.3),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	debris.Lifetime = NumberRange.new(5, 10)
	debris.Rate = 5
	debris.Speed = NumberRange.new(0.2, 0.8)
	debris.SpreadAngle = Vector2.new(360, 360)
	debris.Rotation = NumberRange.new(0, 360)
	debris.RotSpeed = NumberRange.new(-30, 30)
	debris.Acceleration = Vector3.new(0, 0.1, 0) -- Slight upward drift
	debris.Parent = part
	
	table.insert(self._activeEmitters, part)
	self._zoneMaid:GiveTask(part)
	
	return part
end

function ParticleController:SpawnAmbientDust()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end
	
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	-- Check if dust already exists
	if root:FindFirstChild("AmbientDust") then return end
	
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "AmbientDust"
	dust.Texture = "rbxassetid://241685484" -- Subtle sparkle
	dust.Color = ColorSequence.new(Color3.fromRGB(255, 255, 240))
	dust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.15),
		NumberSequenceKeypoint.new(1, 0)
	})
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.6),
		NumberSequenceKeypoint.new(0.7, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	dust.Lifetime = NumberRange.new(2, 4)
	dust.Rate = 2
	dust.Speed = NumberRange.new(0.1, 0.5)
	dust.SpreadAngle = Vector2.new(360, 360)
	dust.Rotation = NumberRange.new(0, 360)
	dust.LightEmission = 0.3
	dust.LightInfluence = 0.5
	dust.Parent = root
	
	self._maid:GiveTask(dust)
	
	return dust
end

function ParticleController:SpawnHitEffect(position, hitType)
	local part = Instance.new("Part")
	part.Name = "HitEffect"
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = Workspace
	
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://243660364"
	emitter.Color = ColorSequence.new(hitType == "critical" and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 100, 100))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Transparency = NumberSequence.new(0, 1)
	emitter.Lifetime = NumberRange.new(0.3, 0.5)
	emitter.Speed = NumberRange.new(5, 10)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 3
	emitter.Parent = part
	emitter:Emit(hitType == "critical" and 20 or 10)
	
	Debris:AddItem(part, 1)
end

function ParticleController:SpawnDeathEffect(position)
	local part = Instance.new("Part")
	part.Name = "DeathEffect"
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = Workspace
	
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://241685484"
	emitter.Color = ColorSequence.new(Color3.fromRGB(100, 0, 150), Color3.fromRGB(50, 0, 80))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 2),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Transparency = NumberSequence.new(0, 1)
	emitter.Lifetime = NumberRange.new(0.8, 1.2)
	emitter.Speed = NumberRange.new(3, 8)
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.Drag = 2
	emitter.LightEmission = 0.5
	emitter.Parent = part
	emitter:Emit(30)
	
	Debris:AddItem(part, 2)
end

function ParticleController:SpawnDamageNumber(position, damage, isCritical)
	local player = Players.LocalPlayer
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "DamageNumber"
	billboardGui.Size = UDim2.new(0, 100, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Adornee = nil
	
	local part = Instance.new("Part")
	part.Name = "DamageAnchor"
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position + Vector3.new(math.random(-1, 1), 1, math.random(-1, 1))
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = Workspace
	
	billboardGui.Adornee = part
	billboardGui.Parent = playerGui
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = isCritical and ("💥" .. tostring(math.floor(damage)) .. "!") or tostring(math.floor(damage))
	label.TextColor3 = isCritical and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextSize = isCritical and 28 or 22
	label.TextScaled = false
	label.Parent = billboardGui
	
	-- Animate upward and fade
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(part, tweenInfo, {Position = part.Position + Vector3.new(0, 3, 0)}):Play()
	TweenService:Create(label, tweenInfo, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	
	Debris:AddItem(part, 1.5)
	Debris:AddItem(billboardGui, 1.5)
end

function ParticleController:DoScreenShake(intensity)
	local camera = Workspace.CurrentCamera
	if not camera then return end
	
	local originalCFrame = camera.CFrame
	local shakeDuration = 0.2
	local startTime = tick()
	
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= shakeDuration then
			connection:Disconnect()
			return
		end
		
		local progress = elapsed / shakeDuration
		local currentIntensity = intensity * (1 - progress)
		local offsetX = (math.random() - 0.5) * 2 * currentIntensity
		local offsetY = (math.random() - 0.5) * 2 * currentIntensity
		
		camera.CFrame = camera.CFrame * CFrame.new(offsetX, offsetY, 0)
	end)
end

function ParticleController:CreateWeaponTrail(weapon)
	if not weapon or not weapon:IsA("BasePart") then return end
	
	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, -weapon.Size.Y/2, 0)
	attachment0.Parent = weapon
	
	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, weapon.Size.Y/2, 0)
	attachment1.Parent = weapon
	
	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 200, 100), Color3.fromRGB(255, 100, 50))
	trail.Transparency = NumberSequence.new(0, 1)
	trail.Lifetime = 0.2
	trail.MinLength = 0.1
	trail.FaceCamera = true
	trail.Enabled = false
	trail.Parent = weapon
	
	self._weaponTrails[weapon] = {trail = trail, att0 = attachment0, att1 = attachment1}
	return trail
end

function ParticleController:EnableWeaponTrail(weapon, enabled)
	local trailData = self._weaponTrails[weapon]
	if trailData and trailData.trail then
		trailData.trail.Enabled = enabled
	end
end

function ParticleController:CleanupZoneEffects()
	self._zoneMaid:DoCleaning()
	self._activeEmitters = {}
end

function ParticleController:Destroy()
	self:CleanupZoneEffects()
	if self._maid then
		self._maid:Destroy()
	end
	if self._zoneMaid then
		self._zoneMaid:Destroy()
	end
end

return ParticleController
