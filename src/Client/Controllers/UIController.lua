--[[

	UIController.lua
	Manages the main HUD and UI updates.

]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maid = require(Shared.Modules.Maid)
local Signal = require(Shared.Modules.Signal)
local Remotes = require(Shared.Remotes)

-- Lazy load Controllers to avoid circular dependency issues during Init
local InventoryController
local CombatController
task.spawn(function()
	InventoryController = require(script.Parent.InventoryController)
	CombatController = require(script.Parent.CombatController)
end)

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

function UIController:Init()
	self.Player = Players.LocalPlayer
	self.PlayerGui = self.Player:WaitForChild("PlayerGui")
	
	self.RequestSkill = Remotes.GetEvent("RequestSkill")
	self.TeleportToHub = Remotes.GetEvent("TeleportToHub")
	
	-- Create main HUD
	self:CreateHUD()
	
	-- Listen for currency changes
	local UpdateHUD = Remotes.GetEvent("UpdateHUD")
	UpdateHUD.OnClientEvent:Connect(function(data)
		if data and data.Currencies then
			self:UpdateCurrencyDisplay(data.Currencies)
		end
	end)
	
	print("UIController: Initialized")
end

function UIController:Start()
	print("[UIController] Starting...")
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
	
	-- 1.5 Menu Buttons (Left Side)
	self:CreateMenuButtons(screenGui)

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
	
	ability1Btn.Activated:Connect(function()
		self:UseSkill("Fireball")
	end)
	
	-- Ability 2
	local ability2Btn = self:CreateActionButton("2", UDim2.new(1, 0, 0.5, 0), THEME.ACCENT_COLOR)
	ability2Btn.Size = UDim2.new(0, 60, 0, 60)
	ability2Btn.Parent = combatFrame
	
	ability2Btn.Activated:Connect(function()
		self:UseSkill("Dash")
	end)
	
	-- Bind Actions
	attackBtn.Activated:Connect(function()
		self:OnAttackPressed()
	end)
	
	-- Mobile/PC Input binding
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.Space then
			self:OnAttackPressed()
		elseif input.KeyCode == Enum.KeyCode.One then
			self:UseSkill("Fireball")
		elseif input.KeyCode == Enum.KeyCode.Two then
			self:UseSkill("Dash")
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

function UIController:CreateMenuButtons(parent)
	local frame = Instance.new("Frame")
	frame.Name = "MenuButtons"
	frame.Size = UDim2.new(0, 60, 0, 200)
	frame.Position = UDim2.new(0, 20, 0, 120)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	
	-- Bag Button
	local bagBtn = self:CreateActionButton("🎒", UDim2.new(0, 0, 0, 0), Color3.fromRGB(100, 100, 150))
	bagBtn.Size = UDim2.new(0, 50, 0, 50)
	bagBtn.LayoutOrder = 1
	bagBtn.Parent = frame
	
	bagBtn.Activated:Connect(function()
		if InventoryController then
			InventoryController:Toggle()
		end
	end)
	
	-- Hub Button
	local hubBtn = self:CreateActionButton("🏠", UDim2.new(0, 0, 0, 0), Color3.fromRGB(50, 150, 100))
	hubBtn.Size = UDim2.new(0, 50, 0, 50)
	hubBtn.LayoutOrder = 2
	hubBtn.Parent = frame
	
	hubBtn.Activated:Connect(function()
		self.TeleportToHub:FireServer()
	end)
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
	if CombatController then
		local target = self:GetRaycastTarget()
		CombatController:AttemptAttack(target)
	end
end

function UIController:UseSkill(skillName)
	local targetPos = self:GetMouseHitPosition()
	if not targetPos then return end
	 self.RequestSkill:FireServer(skillName, targetPos)
end

function UIController:GetMouseHitPosition()
	local camera = Workspace.CurrentCamera
	if not camera then return nil end

	local viewportSize = camera.ViewportSize
	local unitRay = camera:ViewportPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
	
	local raycastParams = RaycastParams.new()
	if self.Player.Character then
		raycastParams.FilterDescendantsInstances = {self.Player.Character}
	end
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 100, raycastParams)
	if result then
		return result.Position
	end
	return unitRay.Origin + (unitRay.Direction * 100)
end

function UIController:GetRaycastTarget()
	local camera = Workspace.CurrentCamera
	if not camera then return nil end

	-- Raycast from center of screen
	local viewportSize = camera.ViewportSize
	local unitRay = camera:ViewportPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
	
	local raycastParams = RaycastParams.new()
	if self.Player.Character then
		raycastParams.FilterDescendantsInstances = {self.Player.Character}
	end
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 100, raycastParams)
	if result and result.Instance then
		return result.Instance
	end
	return nil
end

return UIController
