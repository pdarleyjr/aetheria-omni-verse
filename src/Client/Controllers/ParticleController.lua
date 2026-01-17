--[[
	ParticleController.lua
	Environmental particle system manager for ambient visual effects
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maid = require(Shared.Modules.Maid)

local ParticleController = {}
ParticleController._maid = nil
ParticleController._activeEmitters = {}
ParticleController._zoneMaid = nil

function ParticleController:Init()
	print("[ParticleController] Initializing...")
	self._maid = Maid.new()
	self._zoneMaid = Maid.new()
	self._activeEmitters = {}
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
