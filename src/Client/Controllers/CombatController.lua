--!strict
--[[
	CombatController.lua
	Handles client-side combat input, prediction, and visual effects.
	
	Features:
	- Combat input handling (mouse, touch, keyboard)
	- Client-side prediction for smooth combat
	- Damage number display
	- Visual effects and hit feedback
	- Cooldown management
	- Spirit ability activation
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Only run on client
if not RunService:IsClient() then
	error("CombatController can only be required on the client")
end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Shared modules
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

-- Types
type Ability = {
	Id: string,
	Name: string,
	Cooldown: number,
	LastUsed: number,
}

-- Controller
local CombatController = {
	_initialized = false,
	_attacking = false,
	_lastAttackTime = 0,
	_abilities = {} :: { [number]: Ability },
	_cooldownFrames = {} :: { [string]: Frame },
	_damageNumberLimit = 10, -- Max concurrent damage numbers
	_activeDamageNumbers = 0,
}

-- Check if on cooldown
local function isOnCooldown(lastUsed: number, cooldown: number): boolean
	return (os.clock() - lastUsed) < cooldown
end

-- Get attack cooldown
local function getAttackCooldown(): number
	return 1 / Constants.Combat.AttackRateLimit
end

-- Create damage number
local function createDamageNumber(position: Vector3, damage: number, isCritical: boolean): ()
	if CombatController._activeDamageNumbers >= CombatController._damageNumberLimit then
		return -- Too many active damage numbers
	end
	
	CombatController._activeDamageNumbers += 1
	
	local camera = workspace.CurrentCamera
	if not camera then
		CombatController._activeDamageNumbers -= 1
		return
	end
	
	-- Get screen position
	local screenPos, onScreen = camera:WorldToScreenPoint(position)
	if not onScreen then
		CombatController._activeDamageNumbers -= 1
		return
	end
	
	-- Create damage number UI
	local damageGui = Instance.new("ScreenGui")
	damageGui.Name = "DamageNumber"
	damageGui.Parent = PlayerGui
	damageGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	local damageLabel = Instance.new("TextLabel")
	damageLabel.Parent = damageGui
	damageLabel.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
	damageLabel.Size = UDim2.fromOffset(100, 50)
	damageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	damageLabel.BackgroundTransparency = 1
	damageLabel.Text = tostring(math.floor(damage))
	damageLabel.TextColor3 = isCritical and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 255, 255)
	damageLabel.TextSize = isCritical and 32 or 24
	damageLabel.Font = Enum.Font.GothamBold
	damageLabel.TextStrokeTransparency = 0.5
	damageLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	damageLabel.ZIndex = 10
	
	-- Animate upward and fade out
	local tweenInfo = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(damageLabel, tweenInfo, {
		Position = UDim2.fromOffset(screenPos.X, screenPos.Y - 80),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	
	tween:Play()
	tween.Completed:Connect(function()
		damageGui:Destroy()
		CombatController._activeDamageNumbers -= 1
	end)
end

-- Request attack from server
function CombatController:RequestAttack(targetPosition: Vector3): ()
	-- Check cooldown
	if isOnCooldown(self._lastAttackTime, getAttackCooldown()) then
		return
	end
	
	-- Get character and validate
	local character = LocalPlayer.Character
	if not character then
		return
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	
	-- Check range (client-side prediction)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end
	
	local distance = (rootPart.Position - targetPosition).Magnitude
	if distance > Constants.Combat.MaxAttackRange then
		warn("Target out of range")
		return
	end
	
	-- Send to server
	if _G.Remotes and _G.Remotes.Combat and _G.Remotes.Combat.RequestAttack then
		_G.Remotes.Combat.RequestAttack:FireServer(targetPosition)
		self._lastAttackTime = os.clock()
		self._attacking = true
		
		-- Visual feedback (client-side)
		self:PlayAttackAnimation()
	end
end

-- Play attack animation
function CombatController:PlayAttackAnimation(): ()
	local character = LocalPlayer.Character
	if not character then
		return
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	
	-- Simple punch animation (can be replaced with actual animation)
	-- For now, just provide visual feedback
	print("Playing attack animation")
	
	-- Reset attacking state after animation
	task.delay(0.5, function()
		self._attacking = false
	end)
end

-- Use ability
function CombatController:UseAbility(abilitySlot: number): ()
	local ability = self._abilities[abilitySlot]
	if not ability then
		warn(`No ability in slot {abilitySlot}`)
		return
	end
	
	-- Check cooldown
	if isOnCooldown(ability.LastUsed, ability.Cooldown) then
		warn(`Ability on cooldown: {ability.Name}`)
		return
	end
	
	-- Get character
	local character = LocalPlayer.Character
	if not character then
		return
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	
	-- Send to server
	if _G.Remotes and _G.Remotes.Combat and _G.Remotes.Combat.AbilityCast then
		_G.Remotes.Combat.AbilityCast:FireServer(ability.Id)
		ability.LastUsed = os.clock()
		
		-- Start cooldown UI
		self:StartCooldownAnimation(abilitySlot, ability.Cooldown)
		
		print(`Used ability: {ability.Name}`)
	end
end

-- Start cooldown animation
function CombatController:StartCooldownAnimation(abilitySlot: number, cooldown: number): ()
	local cooldownFrame = self._cooldownFrames[tostring(abilitySlot)]
	if not cooldownFrame then
		return
	end
	
	-- Create a cooldown overlay
	local overlay = cooldownFrame:FindFirstChild("CooldownOverlay")
	if not overlay then
		overlay = Instance.new("Frame")
		overlay.Name = "CooldownOverlay"
		overlay.Parent = cooldownFrame
		overlay.Size = UDim2.new(1, 0, 0, 0)
		overlay.Position = UDim2.new(0, 0, 1, 0)
		overlay.AnchorPoint = Vector2.new(0, 1)
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 0.5
		overlay.BorderSizePixel = 0
		overlay.ZIndex = 5
	end
	
	-- Animate the overlay shrinking
	overlay.Size = UDim2.new(1, 0, 1, 0)
	
	local tweenInfo = TweenInfo.new(cooldown, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(overlay, tweenInfo, {
		Size = UDim2.new(1, 0, 0, 0)
	})
	
	tween:Play()
end

-- Setup ability buttons
local function setupAbilityButtons(): ()
	local aetheriaUI = PlayerGui:WaitForChild("AetheriaUI", 5)
	if not aetheriaUI then
		warn("AetheriaUI not found")
		return
	end
	
	local combatUI = aetheriaUI:WaitForChild("CombatUI", 5)
	if not combatUI then
		return
	end
	
	-- Attack button
	local attackButton = combatUI:FindFirstChild("AttackButton")
	if attackButton then
		-- Add button to detect input
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 1, 0)
		button.BackgroundTransparency = 1
		button.Text = ""
		button.ZIndex = 3
		button.Parent = attackButton
		
		button.MouseButton1Click:Connect(function()
			-- Get mouse position or forward direction
			local mouse = LocalPlayer:GetMouse()
			local targetPosition = mouse.Hit.Position
			CombatController:RequestAttack(targetPosition)
		end)
	end
	
	-- Ability 1 button
	local ability1Button = combatUI:FindFirstChild("Ability1Button")
	if ability1Button then
		CombatController._cooldownFrames["1"] = ability1Button
		
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 1, 0)
		button.BackgroundTransparency = 1
		button.Text = ""
		button.ZIndex = 3
		button.Parent = ability1Button
		
		button.MouseButton1Click:Connect(function()
			CombatController:UseAbility(1)
		end)
	end
	
	-- Ability 2 button
	local ability2Button = combatUI:FindFirstChild("Ability2Button")
	if ability2Button then
		CombatController._cooldownFrames["2"] = ability2Button
		
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 1, 0)
		button.BackgroundTransparency = 1
		button.Text = ""
		button.ZIndex = 3
		button.Parent = ability2Button
		
		button.MouseButton1Click:Connect(function()
			CombatController:UseAbility(2)
		end)
	end
end

-- Setup keyboard input
local function setupKeyboardInput(): ()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		
		-- Attack with left mouse button or Space
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mouse = LocalPlayer:GetMouse()
			CombatController:RequestAttack(mouse.Hit.Position)
		elseif input.KeyCode == Enum.KeyCode.Space then
			local character = LocalPlayer.Character
			if character then
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					local forwardPosition = rootPart.Position + (rootPart.CFrame.LookVector * 10)
					CombatController:RequestAttack(forwardPosition)
				end
			end
		-- Abilities with number keys
		elseif input.KeyCode == Enum.KeyCode.One then
			CombatController:UseAbility(1)
		elseif input.KeyCode == Enum.KeyCode.Two then
			CombatController:UseAbility(2)
		end
	end)
end

-- Initialize controller
function CombatController:Init(): ()
	if self._initialized then
		warn("CombatController already initialized")
		return
	end
	
	print("Initializing CombatController...")
	
	-- Initialize default abilities
	self._abilities[1] = {
		Id = "ability_1",
		Name = "Ability 1",
		Cooldown = 5.0,
		LastUsed = 0,
	}
	
	self._abilities[2] = {
		Id = "ability_2",
		Name = "Ability 2",
		Cooldown = 8.0,
		LastUsed = 0,
	}
	
	self._initialized = true
	print("CombatController initialized")
end

-- Start controller
function CombatController:Start(): ()
	print("Starting CombatController...")
	
	-- Setup input handlers
	setupKeyboardInput()
	
	-- Wait for UI to be ready, then setup buttons
	task.delay(0.5, setupAbilityButtons)
	
	-- Listen for hit confirmations
	if _G.Remotes and _G.Remotes.Combat then
		if _G.Remotes.Combat.HitConfirmed then
			_G.Remotes.Combat.HitConfirmed.OnClientEvent:Connect(function(hitPosition: Vector3)
				-- Play hit effect
				print(`Hit confirmed at {hitPosition}`)
			end)
		end
		
		-- Listen for damage numbers
		if _G.Remotes.Combat.DamageNumber then
			_G.Remotes.Combat.DamageNumber.OnClientEvent:Connect(function(
				position: Vector3,
				damage: number,
				isCritical: boolean
			)
				createDamageNumber(position, damage, isCritical)
			end)
		end
	end
	
	print("CombatController started")
end

-- Handle character respawn
function CombatController:OnCharacterRespawn(character: Model): ()
	print("CombatController: Character respawned")
	-- Reset combat state
	self._attacking = false
	self._lastAttackTime = 0
	
	-- Reset ability cooldowns
	for _, ability in self._abilities do
		ability.LastUsed = 0
	end
end

return CombatController
