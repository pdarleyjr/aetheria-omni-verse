--!strict
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

local CombatController = {}
local lastAttackTime = 0

function CombatController:Init()
	print("[CombatController] Initializing...")
	
	local showDamageRemote = Remotes.GetEvent("ShowDamage")
	showDamageRemote.OnClientEvent:Connect(function(targetPart, damage, isCritical)
		self:ShowDamageNumber(targetPart, damage, isCritical)
	end)
end

function CombatController:Start()
	print("[CombatController] Starting...")
	
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self:AttemptAttack()
		end
	end)
end

function CombatController:ShowDamageNumber(targetPart, damage, isCritical)
	if not targetPart then return end
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DamageNumber"
	billboard.Adornee = targetPart
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "-" .. tostring(damage)
	label.TextColor3 = isCritical and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextSize = isCritical and 24 or 18
	label.Parent = billboard
	
	billboard.Parent = Players.LocalPlayer.PlayerGui
	
	-- Animation
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = { StudsOffset = Vector3.new(0, 5, 0) }
	local tween = TweenService:Create(billboard, tweenInfo, goal)
	
	local fadeTween = TweenService:Create(label, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 })
	
	tween:Play()
	fadeTween:Play()
	
	task.delay(1, function()
		billboard:Destroy()
	end)
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
					
					-- Send to server
					local attackRemote = Remotes.GetEvent("RequestAttack")
					attackRemote:FireServer(model)
				end
			end
		end
	end
end

return CombatController
