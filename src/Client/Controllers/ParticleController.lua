--[[
	ParticleController.lua
	Environmental particle system manager for ambient visual effects
	NOTE: Combat visuals (damage numbers, hit effects, screen shake) are in VisualsController
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maid = require(Shared.Modules.Maid)
local Remotes = require(Shared.Remotes)

local ParticleController = {}
ParticleController._maid = nil
ParticleController._activeEmitters = {}
ParticleController._zoneMaid = nil
ParticleController._weaponTrails = {}
ParticleController._environmentalEmitters = {}

-- Object pooling for particle emitters
ParticleController._emitterPool = {}
ParticleController._emitterPoolSize = 100
ParticleController._emitterPoolIndex = 1

-- Performance limits
local MAX_FOG_EMITTERS = 3
local MAX_DEBRIS_EMITTERS = 3
local MAX_DUST_EMITTERS = 3
local HUB_RADIUS = 150

-- LOD distance thresholds
local LOD_SKIP_DISTANCE = 200
local LOD_REDUCE_DISTANCE = 100

function ParticleController:Init()
	print("[ParticleController] Initializing...")
	self._maid = Maid.new()
	self._zoneMaid = Maid.new()
	self._activeEmitters = {}
	self._weaponTrails = {}
	self._environmentalEmitters = {
		fog = {},
		debris = {},
		dust = {}
	}
	
	-- Initialize emitter pool
	self:CreateEmitterPool()
	
	-- Listen for enemy death (environmental effect only - souls rising)
	local OnEnemyDeath = Remotes.GetEvent("OnEnemyDeath")
	self._maid:GiveTask(OnEnemyDeath.OnClientEvent:Connect(function(position)
		self:SpawnDeathEffect(position)
	end))
	
	-- Spawn environmental effects
	self:SpawnEnvironmentalEffects()
end

function ParticleController:Start()
	print("[ParticleController] Starting...")
	
	local player = Players.LocalPlayer
	
	-- Cleanup on character respawn
	self._maid:GiveTask(player.CharacterAdded:Connect(function()
		self:CleanupZoneEffects()
		task.delay(1, function()
			self:SpawnAmbientDust()
			self:UpdateEnvironmentalIntensity()
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
	
	-- Update environmental intensity based on player position
	self._maid:GiveTask(RunService.Heartbeat:Connect(function()
		self:UpdateEnvironmentalIntensity()
	end))
end

--[[
	Environmental "Cohesive Chaos" Particles
	Creates atmospheric effects that increase with distance from Hub
]]
function ParticleController:SpawnEnvironmentalEffects()
	-- Create fog layer attached to Workspace
	self:SpawnVolumetricFog()
	
	-- Create floating debris/ash
	self:SpawnFloatingAsh()
	
	-- Create ambient dust motes with light interaction
	self:SpawnLightReactiveDust()
end

function ParticleController:SpawnVolumetricFog()
	-- Cleanup existing
	for _, emitter in ipairs(self._environmentalEmitters.fog) do
		if emitter and emitter.Parent then
			emitter:Destroy()
		end
	end
	self._environmentalEmitters.fog = {}
	
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end
	
	for i = 1, MAX_FOG_EMITTERS do
		local part = Instance.new("Part")
		part.Name = "VolumetricFog_" .. i
		part.Size = Vector3.new(100, 1, 100)
		part.Position = Vector3.new(0, 2, 0) + Vector3.new((i - 2) * 80, 0, 0)
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Parent = Workspace
		
		local fog = Instance.new("ParticleEmitter")
		fog.Name = "GroundFog"
		fog.Texture = "rbxassetid://243660364"
		fog.Color = ColorSequence.new(Color3.fromRGB(180, 180, 200))
		fog.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 15),
			NumberSequenceKeypoint.new(1, 20)
		})
		fog.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0.85),
			NumberSequenceKeypoint.new(0.8, 0.85),
			NumberSequenceKeypoint.new(1, 1)
		})
		fog.Lifetime = NumberRange.new(10, 15)
		fog.Rate = 1 -- Low rate, slow-moving
		fog.Speed = NumberRange.new(0.2, 0.8)
		fog.SpreadAngle = Vector2.new(180, 0)
		fog.Rotation = NumberRange.new(0, 360)
		fog.RotSpeed = NumberRange.new(-5, 5)
		fog.EmissionDirection = Enum.NormalId.Top
		fog.Parent = part
		
		table.insert(self._environmentalEmitters.fog, part)
		self._maid:GiveTask(part)
	end
end

function ParticleController:SpawnFloatingAsh()
	-- Cleanup existing
	for _, emitter in ipairs(self._environmentalEmitters.debris) do
		if emitter and emitter.Parent then
			emitter:Destroy()
		end
	end
	self._environmentalEmitters.debris = {}
	
	for i = 1, MAX_DEBRIS_EMITTERS do
		local part = Instance.new("Part")
		part.Name = "FloatingAsh_" .. i
		part.Size = Vector3.new(80, 40, 80)
		part.Position = Vector3.new(0, 25, 0) + Vector3.new((i - 2) * 60, 0, (i - 2) * 30)
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Parent = Workspace
		
		local ash = Instance.new("ParticleEmitter")
		ash.Name = "FloatingAsh"
		ash.Texture = "rbxassetid://304846479"
		ash.Color = ColorSequence.new(Color3.fromRGB(120, 110, 100), Color3.fromRGB(80, 75, 70))
		ash.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.5, 0.15),
			NumberSequenceKeypoint.new(1, 0.05)
		})
		ash.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.4),
			NumberSequenceKeypoint.new(0.7, 0.4),
			NumberSequenceKeypoint.new(1, 1)
		})
		ash.Lifetime = NumberRange.new(8, 15)
		ash.Rate = 2 -- Sparse
		ash.Speed = NumberRange.new(0.1, 0.5)
		ash.SpreadAngle = Vector2.new(360, 360)
		ash.Rotation = NumberRange.new(0, 360)
		ash.RotSpeed = NumberRange.new(-20, 20)
		ash.Acceleration = Vector3.new(0, -0.05, 0) -- Very slow fall
		ash.Drag = 1
		ash.Parent = part
		
		table.insert(self._environmentalEmitters.debris, part)
		self._maid:GiveTask(part)
	end
end

function ParticleController:SpawnLightReactiveDust()
	-- Cleanup existing
	for _, emitter in ipairs(self._environmentalEmitters.dust) do
		if emitter and emitter.Parent then
			emitter:Destroy()
		end
	end
	self._environmentalEmitters.dust = {}
	
	for i = 1, MAX_DUST_EMITTERS do
		local part = Instance.new("Part")
		part.Name = "DustMotes_" .. i
		part.Size = Vector3.new(60, 30, 60)
		part.Position = Vector3.new(0, 15, 0) + Vector3.new((i - 2) * 50, 0, (i - 2) * 25)
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Parent = Workspace
		
		local dust = Instance.new("ParticleEmitter")
		dust.Name = "LightDust"
		dust.Texture = "rbxassetid://241685484"
		dust.Color = ColorSequence.new(Color3.fromRGB(255, 250, 230))
		dust.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.1),
			NumberSequenceKeypoint.new(0.7, 0.1),
			NumberSequenceKeypoint.new(1, 0)
		})
		dust.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.5),
			NumberSequenceKeypoint.new(0.7, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		})
		dust.Lifetime = NumberRange.new(3, 6)
		dust.Rate = 3
		dust.Speed = NumberRange.new(0.05, 0.3)
		dust.SpreadAngle = Vector2.new(360, 360)
		dust.Rotation = NumberRange.new(0, 360)
		dust.LightEmission = 0.4 -- Reacts to lighting
		dust.LightInfluence = 0.8 -- High light influence
		dust.Parent = part
		
		table.insert(self._environmentalEmitters.dust, part)
		self._maid:GiveTask(part)
	end
end

function ParticleController:UpdateEnvironmentalIntensity()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character or not character.PrimaryPart then return end
	
	local playerPos = character.PrimaryPart.Position
	local distanceFromHub = playerPos.Magnitude
	
	-- Calculate intensity factor (0 at hub, 1 at max distance)
	local intensity = math.clamp((distanceFromHub - HUB_RADIUS) / 500, 0, 1)
	
	-- Update fog emitter positions to follow player and adjust intensity
	for _, fogPart in ipairs(self._environmentalEmitters.fog) do
		if fogPart and fogPart.Parent then
			-- Move fog near player
			fogPart.Position = Vector3.new(playerPos.X, 2, playerPos.Z) + Vector3.new(math.random(-50, 50), 0, math.random(-50, 50))
			
			local emitter = fogPart:FindFirstChild("GroundFog")
			if emitter then
				emitter.Rate = 0.5 + (intensity * 2) -- 0.5-2.5 rate based on distance
			end
		end
	end
	
	-- Update debris/ash intensity
	for _, ashPart in ipairs(self._environmentalEmitters.debris) do
		if ashPart and ashPart.Parent then
			ashPart.Position = Vector3.new(playerPos.X, 25, playerPos.Z) + Vector3.new(math.random(-40, 40), math.random(-10, 10), math.random(-40, 40))
			
			local emitter = ashPart:FindFirstChild("FloatingAsh")
			if emitter then
				emitter.Rate = 1 + (intensity * 4) -- 1-5 rate based on distance
				emitter.Speed = NumberRange.new(0.1 + intensity * 0.3, 0.5 + intensity * 1)
			end
		end
	end
	
	-- Update dust motes
	for _, dustPart in ipairs(self._environmentalEmitters.dust) do
		if dustPart and dustPart.Parent then
			dustPart.Position = Vector3.new(playerPos.X, 15, playerPos.Z) + Vector3.new(math.random(-30, 30), math.random(-5, 10), math.random(-30, 30))
			
			local emitter = dustPart:FindFirstChild("LightDust")
			if emitter then
				emitter.Rate = 2 + (intensity * 5) -- 2-7 rate based on distance
			end
		end
	end
end

function ParticleController:CreateEmitterPool()
	self._emitterPool = {}
	for i = 1, self._emitterPoolSize do
		local part = Instance.new("Part")
		part.Name = "PooledEmitter_" .. i
		part.Size = Vector3.new(1, 1, 1)
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Parent = nil -- Start unparented
		
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "PooledParticles"
		emitter.Rate = 0
		emitter.Parent = part
		
		table.insert(self._emitterPool, {part = part, emitter = emitter, inUse = false})
	end
	print("[ParticleController] Created pool of " .. self._emitterPoolSize .. " particle emitters")
end

function ParticleController:GetFromPool()
	-- Round-robin through pool
	for i = 1, self._emitterPoolSize do
		local index = ((self._emitterPoolIndex - 1 + i) % self._emitterPoolSize) + 1
		local poolItem = self._emitterPool[index]
		if not poolItem.inUse then
			poolItem.inUse = true
			self._emitterPoolIndex = index + 1
			return poolItem
		end
	end
	-- All in use, reuse oldest
	local oldest = self._emitterPool[self._emitterPoolIndex]
	self._emitterPoolIndex = (self._emitterPoolIndex % self._emitterPoolSize) + 1
	return oldest
end

function ParticleController:ReturnToPool(poolItem)
	poolItem.inUse = false
	poolItem.part.Parent = nil
	poolItem.emitter:Clear()
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

function ParticleController:SpawnDeathEffect(position)
	-- LOD check
	local camera = Workspace.CurrentCamera
	if camera then
		local distance = (position - camera.CFrame.Position).Magnitude
		if distance > LOD_SKIP_DISTANCE then
			return -- Skip effect entirely
		end
	end
	
	local poolItem = self:GetFromPool()
	local part = poolItem.part
	local emitter = poolItem.emitter
	
	part.Position = position
	part.Parent = Workspace
	
	-- Configure emitter for death effect
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
	
	-- LOD: reduce particle count at distance
	local emitCount = 30
	if camera then
		local distance = (position - camera.CFrame.Position).Magnitude
		if distance > LOD_REDUCE_DISTANCE then
			emitCount = 15 -- Reduce by 50%
		end
	end
	emitter:Emit(emitCount)
	
	task.delay(2, function()
		self:ReturnToPool(poolItem)
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
