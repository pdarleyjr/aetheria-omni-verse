--!strict
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Constants = require(Shared.Modules.Constants)
local Maid = require(Shared.Modules.Maid)

local VisualsController = require(script.Parent.VisualsController)
local SFXController = require(script.Parent.SFXController)

local CombatController = {}
CombatController._maid = nil
CombatController._screenShakeIntensity = 1.0 -- 0-1 accessibility setting
local lastAttackTime = 0

function CombatController:Init()
	print("[CombatController] Initializing...")
	
	self._maid = Maid.new()
	self.RequestAttack = Remotes.GetEvent("RequestAttack")
end

function CombatController:Start()
	print("[CombatController] Starting...")
	
	local player = Players.LocalPlayer
	
	-- Cleanup when player leaves
	self._maid:GiveTask(Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == player then
			self:Destroy()
		end
	end))
	
	-- Input handling moved to UIController/ContextActionService
end

--[[
	Screen Shake System
	Intensity presets: light (0.1), medium (0.3), heavy (0.5)
	Uses CFrame manipulation via VisualsController
]]
function CombatController:ShakeCamera(intensity, duration)
	-- Apply accessibility intensity multiplier
	local adjustedIntensity = intensity * self._screenShakeIntensity
	if adjustedIntensity <= 0 then return end
	VisualsController:ShakeCamera(duration or 0.2, adjustedIntensity)
end

-- Convenience methods for preset intensities
function CombatController:ShakeCameraLight(duration)
	self:ShakeCamera(Constants.SCREEN_SHAKE.LIGHT, duration or 0.1)
end

function CombatController:ShakeCameraMedium(duration)
	self:ShakeCamera(Constants.SCREEN_SHAKE.MEDIUM, duration or 0.15)
end

function CombatController:ShakeCameraHeavy(duration)
	self:ShakeCamera(Constants.SCREEN_SHAKE.HEAVY, duration or 0.25)
end

function CombatController:ShakeCameraForDamage(damage, duration)
	local intensity = Constants.SCREEN_SHAKE.GetIntensityForDamage(damage)
	self:ShakeCamera(intensity, duration)
end

--[[
	Hit-Stop Frames
	0.05-0.1 second pause on impactful hits
	Critical hits get longer pause
]]
function CombatController:ApplyHitStop(isCritical, damage)
	local baseDuration = isCritical and Constants.HITSTOP.CRITICAL_DURATION or Constants.HITSTOP.NORMAL_DURATION
	-- Scale duration with damage (up to 50% longer for high damage)
	local damageScale = math.clamp(damage / 100, 0, 0.5)
	local duration = baseDuration * (1 + damageScale)
	VisualsController:ApplyHitstop(duration)
end

-- Accessibility: Set screen shake intensity (0-100%)
function CombatController:SetScreenShakeIntensity(percent)
	self._screenShakeIntensity = math.clamp(percent / 100, 0, 1)
end

function CombatController:AttemptAttack(overrideTarget)
	local now = os.clock()
	if now - lastAttackTime < Constants.COMBAT.COOLDOWN then
		return
	end
	
	local target = overrideTarget
	
	if not target then
		local player = Players.LocalPlayer
		local mouse = player:GetMouse()
		target = mouse.Target
	end
	
	if target and target.Parent then
		local model = target.Parent
		if model:IsA("Accessory") then
			model = model.Parent
		end
		
		if model and model:FindFirstChild("Humanoid") then
			-- Check distance locally for immediate feedback/prevention
			local player = Players.LocalPlayer
			local character = player.Character
			if character and character.PrimaryPart and model.PrimaryPart then
				local distance = (character.PrimaryPart.Position - model.PrimaryPart.Position).Magnitude
				if distance <= Constants.COMBAT.MAX_DISTANCE then
					lastAttackTime = now
					
					-- Visuals (Placeholder)
					print("[CombatController] Attacking " .. model.Name)
					
					if character.PrimaryPart then
						VisualsController:PlayAttackEffect(character.PrimaryPart.Position, model.PrimaryPart.Position)
					end

					-- Send to server
					self.RequestAttack:FireServer(model)
				end
			end
		end
	end
end

function CombatController:Destroy()
	if self._maid then
		self._maid:Destroy()
	end
end

return CombatController
