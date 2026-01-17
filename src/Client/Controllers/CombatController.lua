--!strict
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

local VisualsController = require(script.Parent.VisualsController)

local CombatController = {}
local lastAttackTime = 0

function CombatController:Init()
	print("[CombatController] Initializing...")
	
	self.RequestAttack = Remotes.GetEvent("RequestAttack")
end

function CombatController:Start()
	print("[CombatController] Starting...")
	
	-- Input handling moved to UIController/ContextActionService
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

return CombatController
