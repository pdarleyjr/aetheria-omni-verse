--[[
	UIController.lua
	Manages the main HUD and UI updates.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maid = require(Shared.Modules.Maid)
local Signal = require(Shared.Modules.Signal)

local UIController = {}
UIController.Maid = Maid.new()

-- Theme Constants
local THEME = {
	GLASS_COLOR = Color3.fromRGB(20, 20, 35),
	GLASS_TRANSPARENCY = 0.25,
	ACCENT_COLOR = Color3.fromRGB(0, 170, 255),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	FONT = Enum.Font.GothamBold,
	CORNER_RADIUS = UDim.new(0, 12)
}

function UIController:Initialize(playerData)
	self.Player = Players.LocalPlayer
	self.PlayerGui = self.Player:WaitForChild("PlayerGui")
	
	-- Create main HUD
	self:CreateHUD()
	
	-- Initial update
	if playerData and playerData.Currencies then
		self:UpdateCurrencyDisplay(playerData.Currencies)
	end
	
	-- Listen for currency changes
	local DataChangedEvent = ReplicatedStorage.Shared.Remotes.Data:WaitForChild("DataChanged")
	DataChangedEvent.OnClientEvent:Connect(function(path, newValue)
		if path == "Currencies" then
			self:UpdateCurrencyDisplay(newValue)
		end
	end)
	
	print("UIController: Initialized")
end

function UIController:CreateHUD()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = self.PlayerGui
	self.ScreenGui = screenGui
	
	-- 1. Currency Panel (Top Left)
	local currencyFrame = self:CreateGlassPanel(UDim2.new(0, 220, 0, 90), UDim2.new(0, 20, 0, 20))
	currencyFrame.Name = "CurrencyPanel"
	currencyFrame.Parent = screenGui
	
	self.EssenceLabel = self:CreateCurrencyLabel("Essence", "✨", 0, currencyFrame)
	self.AetherLabel = self:CreateCurrencyLabel("Aether", "💎", 1, currencyFrame)
	self.CrystalsLabel = self:CreateCurrencyLabel("Crystals", "🔮", 2, currencyFrame)
	
	-- 2. Combat Controls (Bottom Right)
	local combatFrame = Instance.new("Frame")
	combatFrame.Name = "CombatControls"
	combatFrame.Size = UDim2.new(0, 200, 0, 200)
	combatFrame.Position = UDim2.new(1, -220, 1, -220)
	combatFrame.BackgroundTransparency = 1
	combatFrame.Parent = screenGui
	
	-- Attack Button
	local attackBtn = self:CreateActionButton("⚔️", UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(255, 80, 80))
	attackBtn.Parent = combatFrame
	
	-- Ability 1
	local ability1Btn = self:CreateActionButton("1", UDim2.new(0, 0, 0.5, 0), THEME.ACCENT_COLOR)
	ability1Btn.Size = UDim2.new(0, 60, 0, 60)
	ability1Btn.Parent = combatFrame
	
	-- Ability 2
	local ability2Btn = self:CreateActionButton("2", UDim2.new(1, 0, 0.5, 0), THEME.ACCENT_COLOR)
	ability2Btn.Size = UDim2.new(0, 60, 0, 60)
	ability2Btn.Parent = combatFrame
	
	-- Bind Actions
	attackBtn.Activated:Connect(function()
		self:OnAttackPressed()
	end)
	
	-- Mobile/PC Input binding
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.Space then
			self:OnAttackPressed()
		end
	end)
end

function UIController:CreateGlassPanel(size, position)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = THEME.GLASS_COLOR
	frame.BackgroundTransparency = THEME.GLASS_TRANSPARENCY
	frame.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = THEME.CORNER_RADIUS
	corner.Parent = frame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.8
	stroke.Parent = frame
	
	return frame
end

function UIController:CreateCurrencyLabel(name, icon, order, parent)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, -20, 0, 25)
	label.Position = UDim2.new(0, 10, 0, 10 + (order * 25))
	label.BackgroundTransparency = 1
	label.Text = icon .. " " .. name .. ": 0"
	label.TextColor3 = THEME.TEXT_COLOR
	label.Font = THEME.FONT
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

function UIController:CreateActionButton(text, position, color)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 80, 0, 80)
	btn.Position = position
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = color
	btn.Text = text
	btn.TextSize = 24
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = THEME.FONT
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = btn
	
	return btn
end

function UIController:UpdateCurrencyDisplay(currencies)
	if not currencies then return end
	
	if currencies.Essence then
		self.EssenceLabel.Text = "✨ Essence: " .. self:FormatNumber(currencies.Essence)
	end
	if currencies.Aether then
		self.AetherLabel.Text = "💎 Aether: " .. self:FormatNumber(currencies.Aether)
	end
	if currencies.Crystals then
		self.CrystalsLabel.Text = "🔮 Crystals: " .. self:FormatNumber(currencies.Crystals)
	end
end

function UIController:FormatNumber(n)
	return tostring(n)
end

function UIController:OnAttackPressed()
	-- Visual feedback
	local RequestAttack = ReplicatedStorage.Shared.Remotes.Combat:FindFirstChild("RequestAttack")
	if RequestAttack then
		local targetPos = Vector3.new(0, 0, 0) -- Default forward
		if self.Player.Character then
			targetPos = self.Player.Character:GetPivot().Position + self.Player.Character:GetPivot().LookVector * 10
		end
		RequestAttack:FireServer(targetPos)
	end
end

return UIController
