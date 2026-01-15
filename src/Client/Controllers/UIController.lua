--!strict
--[[
	UIController.lua
	Manages UI visibility, transitions, and responsive design for Aetheria.
	
	Features:
	- Mobile-first responsive design with large touch targets
	- Glassmorphism theme implementation
	- HUD management (currency, health, abilities)
	- Screen size detection and adaptation
	- UI state management and transitions
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Only run on client
if not RunService:IsClient() then
	error("UIController can only be required on the client")
end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Shared modules
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

-- Types
type CurrencyData = {
	Aether: number,
	Essence: number,
	Crystals: number,
}

-- Controller
local UIController = {
	_initialized = false,
	_screenGui = nil :: ScreenGui?,
	_hudFrame = nil :: Frame?,
	_currencyDisplays = {} :: { [string]: TextLabel },
	_isMobile = false,
	_screenSize = Vector2.new(0, 0),
}

-- Check if device is mobile
local function checkIfMobile(): boolean
	local touchEnabled = UserInputService.TouchEnabled
	local keyboardEnabled = UserInputService.KeyboardEnabled
	local gamepadEnabled = UserInputService.GamepadEnabled
	
	-- If touch is enabled but no keyboard/gamepad, likely mobile
	return touchEnabled and not (keyboardEnabled or gamepadEnabled)
end

-- Get screen size
local function getScreenSize(): Vector2
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

-- Create glassmorphic frame
local function createGlassFrame(name: string, parent: GuiObject, position: UDim2, size: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Parent = parent
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = Constants.UI.BackgroundColor
	frame.BackgroundTransparency = Constants.UI.GlassTransparency
	frame.BorderSizePixel = 0
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	
	-- Add UI stroke for glass effect
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.8
	stroke.Thickness = 1
	stroke.Parent = frame
	
	return frame
end

-- Create currency display
local function createCurrencyDisplay(currencyType: string, icon: string, parent: Frame, layoutOrder: number): TextLabel
	local container = Instance.new("Frame")
	container.Name = `{currencyType}Container`
	container.Parent = parent
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundTransparency = 1
	container.LayoutOrder = layoutOrder
	
	-- Icon
	local iconLabel = Instance.new("ImageLabel")
	iconLabel.Name = "Icon"
	iconLabel.Parent = container
	iconLabel.Size = UDim2.fromOffset(32, 32)
	iconLabel.Position = UDim2.fromOffset(8, 4)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Image = icon
	
	-- Amount label
	local amountLabel = Instance.new("TextLabel")
	amountLabel.Name = "Amount"
	amountLabel.Parent = container
	amountLabel.Position = UDim2.new(0, 48, 0, 0)
	amountLabel.Size = UDim2.new(1, -56, 1, 0)
	amountLabel.BackgroundTransparency = 1
	amountLabel.Text = "0"
	amountLabel.TextColor3 = Constants.UI.TextColor
	amountLabel.TextSize = 18
	amountLabel.TextXAlignment = Enum.TextXAlignment.Left
	amountLabel.Font = Enum.Font.GothamBold
	
	return amountLabel
end

-- Create HUD
local function createHUD(screenGui: ScreenGui): Frame
	local hudFrame = createGlassFrame(
		"HUD",
		screenGui,
		UDim2.new(0, 10, 0, 10),
		UDim2.new(0, 280, 0, 180)
	)
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Parent = hudFrame
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.fromOffset(0, 8)
	title.BackgroundTransparency = 1
	title.Text = "Resources"
	title.TextColor3 = Constants.UI.AccentColor
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	
	-- Currency container
	local currencyContainer = Instance.new("Frame")
	currencyContainer.Name = "CurrencyContainer"
	currencyContainer.Parent = hudFrame
	currencyContainer.Position = UDim2.fromOffset(10, 45)
	currencyContainer.Size = UDim2.new(1, -20, 1, -55)
	currencyContainer.BackgroundTransparency = 1
	
	-- Add list layout
	local listLayout = Instance.new("UIListLayout")
	listLayout.Parent = currencyContainer
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)
	
	-- Create currency displays
	UIController._currencyDisplays.Essence = createCurrencyDisplay(
		"Essence",
		Constants.Currency.Essence.Icon,
		currencyContainer,
		1
	)
	
	UIController._currencyDisplays.Aether = createCurrencyDisplay(
		"Aether",
		Constants.Currency.Aether.Icon,
		currencyContainer,
		2
	)
	
	UIController._currencyDisplays.Crystals = createCurrencyDisplay(
		"Crystals",
		Constants.Currency.Crystals.Icon,
		currencyContainer,
		3
	)
	
	return hudFrame
end

-- Create combat UI
local function createCombatUI(screenGui: ScreenGui, isMobile: boolean): Frame
	local buttonSize = isMobile and Constants.UI.MinTouchTargetSize or UDim2.fromOffset(70, 70)
	
	local combatFrame = Instance.new("Frame")
	combatFrame.Name = "CombatUI"
	combatFrame.Parent = screenGui
	combatFrame.AnchorPoint = Vector2.new(1, 1)
	combatFrame.Position = UDim2.new(1, -10, 1, -10)
	combatFrame.Size = UDim2.new(0, 300, 0, 100)
	combatFrame.BackgroundTransparency = 1
	
	-- Attack button
	local attackButton = createGlassFrame(
		"AttackButton",
		combatFrame,
		UDim2.new(1, -100, 1, -100),
		buttonSize
	)
	attackButton.ZIndex = 2
	
	local attackLabel = Instance.new("TextLabel")
	attackLabel.Parent = attackButton
	attackLabel.Size = UDim2.new(1, 0, 1, 0)
	attackLabel.BackgroundTransparency = 1
	attackLabel.Text = "⚔️"
	attackLabel.TextColor3 = Constants.UI.TextColor
	attackLabel.TextSize = 28
	attackLabel.Font = Enum.Font.GothamBold
	
	-- Ability 1 button
	local ability1Button = createGlassFrame(
		"Ability1Button",
		combatFrame,
		UDim2.new(1, -200, 1, -100),
		buttonSize
	)
	ability1Button.ZIndex = 2
	
	local ability1Label = Instance.new("TextLabel")
	ability1Label.Parent = ability1Button
	ability1Label.Size = UDim2.new(1, 0, 1, 0)
	ability1Label.BackgroundTransparency = 1
	ability1Label.Text = "1"
	ability1Label.TextColor3 = Constants.UI.TextColor
	ability1Label.TextSize = 24
	ability1Label.Font = Enum.Font.GothamBold
	
	-- Ability 2 button
	local ability2Button = createGlassFrame(
		"Ability2Button",
		combatFrame,
		UDim2.new(1, -200, 1, -200),
		buttonSize
	)
	ability2Button.ZIndex = 2
	
	local ability2Label = Instance.new("TextLabel")
	ability2Label.Parent = ability2Button
	ability2Label.Size = UDim2.new(1, 0, 1, 0)
	ability2Label.BackgroundTransparency = 1
	ability2Label.Text = "2"
	ability2Label.TextColor3 = Constants.UI.TextColor
	ability2Label.TextSize = 24
	ability2Label.Font = Enum.Font.GothamBold
	
	return combatFrame
end

-- Update currency display with animation
function UIController:UpdateCurrency(currencyType: string, amount: number): ()
	local display = self._currencyDisplays[currencyType]
	if not display then
		warn(`Currency display not found: {currencyType}`)
		return
	end
	
	-- Get current amount
	local currentAmount = tonumber(display.Text) or 0
	
	-- Animate the change
	local tweenInfo = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	
	-- Create a number value to tween
	local numberValue = Instance.new("NumberValue")
	numberValue.Value = currentAmount
	
	local tween = TweenService:Create(numberValue, tweenInfo, { Value = amount })
	
	numberValue.Changed:Connect(function(value)
		display.Text = tostring(math.floor(value))
	end)
	
	tween:Play()
	tween.Completed:Connect(function()
		numberValue:Destroy()
	end)
	
	-- Flash effect
	local originalColor = display.TextColor3
	display.TextColor3 = Constants.UI.AccentColor
	task.wait(0.2)
	display.TextColor3 = originalColor
end

-- Show/hide UI with tween
function UIController:ShowUI(uiElement: GuiObject, show: boolean): ()
	local tweenInfo = TweenInfo.new(
		Constants.UI.TweenSpeed,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	
	local targetTransparency = show and 0 or 1
	local tween = TweenService:Create(uiElement, tweenInfo, {
		BackgroundTransparency = targetTransparency
	})
	
	tween:Play()
end

-- Handle screen resize
local function onScreenSizeChanged(): ()
	UIController._screenSize = getScreenSize()
	
	-- Adjust UI based on screen size
	if UIController._hudFrame then
		-- Scale HUD on smaller screens
		if UIController._screenSize.X < 800 then
			UIController._hudFrame.Size = UDim2.new(0, 240, 0, 160)
		else
			UIController._hudFrame.Size = UDim2.new(0, 280, 0, 180)
		end
	end
end

-- Initialize controller
function UIController:Init(): ()
	if self._initialized then
		warn("UIController already initialized")
		return
	end
	
	print("Initializing UIController...")
	
	-- Detect device type
	self._isMobile = checkIfMobile()
	self._screenSize = getScreenSize()
	
	print(`Device type: {self._isMobile and "Mobile" or "Desktop"}`)
	print(`Screen size: {self._screenSize.X}x{self._screenSize.Y}`)
	
	self._initialized = true
	print("UIController initialized")
end

-- Start controller
function UIController:Start(): ()
	print("Starting UIController...")
	
	-- Create main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AetheriaUI"
	screenGui.Parent = PlayerGui
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	self._screenGui = screenGui
	
	-- Create HUD
	self._hudFrame = createHUD(screenGui)
	
	-- Create combat UI
	createCombatUI(screenGui, self._isMobile)
	
	-- Set initial currency values
	self:UpdateCurrency("Essence", Constants.Currency.Essence.StartingAmount)
	self:UpdateCurrency("Aether", Constants.Currency.Aether.StartingAmount)
	self:UpdateCurrency("Crystals", Constants.Currency.Crystals.StartingAmount)
	
	-- Listen for screen size changes
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(onScreenSizeChanged)
	
	-- Listen for data updates
	if _G.Remotes and _G.Remotes.Data and _G.Remotes.Data.DataChanged then
		_G.Remotes.Data.DataChanged.OnClientEvent:Connect(function(path: { string }, value: any)
			-- Handle currency updates
			if path[1] == "Currencies" and path[2] then
				self:UpdateCurrency(path[2], value)
			end
		end)
	end
	
	print("UIController started")
end

-- Handle character respawn
function UIController:OnCharacterRespawn(character: Model): ()
	print("UIController: Character respawned, refreshing UI")
	-- UI persists across respawns due to ResetOnSpawn = false
end

return UIController
