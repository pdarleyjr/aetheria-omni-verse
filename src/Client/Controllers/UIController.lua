--[[
	UIController.lua
	Handles all UI-related functionality with tweened animations
	Phase 37 - Subtask 6: Visual & UI Polish - "Cohesive Chaos" aesthetic
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local Maid = require(ReplicatedStorage.Shared.Modules.Maid)

local UIController = {}
UIController.__index = UIController

-- Theme configuration - Glassmorphism "Cohesive Chaos" aesthetic
local THEME = {
	BACKGROUND_COLOR = Color3.fromRGB(20, 20, 30),
	PANEL_COLOR = Color3.fromRGB(30, 30, 45),
	ACCENT_COLOR = Color3.fromRGB(100, 80, 200),
	ACCENT_SECONDARY = Color3.fromRGB(200, 80, 150),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	TEXT_MUTED = Color3.fromRGB(180, 180, 200),
	SUCCESS_COLOR = Color3.fromRGB(80, 200, 120),
	ERROR_COLOR = Color3.fromRGB(255, 80, 80),
	WARNING_COLOR = Color3.fromRGB(255, 180, 50),
	GLASS_TRANSPARENCY = 0.15,
	STROKE_COLOR = Color3.fromRGB(100, 100, 150),
	FONT = Enum.Font.GothamBold,
	CORNER_RADIUS = UDim.new(0, 12)
}

-- Animation constants - Phase 37 specifications
local ANIM = {
	PANEL_OPEN_TIME = 0.3,
	PANEL_CLOSE_TIME = 0.25,
	EASING_STYLE = Enum.EasingStyle.Quart,
	EASING_DIRECTION = Enum.EasingDirection.Out,
	HOVER_SCALE = 1.05,
	HOVER_BRIGHTNESS = 1.1,
	CLICK_SCALE = 0.95,
	CLICK_DURATION = 0.1,
	BAR_TRANSITION_TIME = 0.3,
	GOLD_INCREMENT_TIME = 0.5,
	NOTIFICATION_SLIDE_TIME = 0.3
}

-- Notification types
local NOTIFICATION_TYPES = {
	info = { Icon = "ℹ️", Color = THEME.ACCENT_COLOR },
	success = { Icon = "✓", Color = THEME.SUCCESS_COLOR },
	error = { Icon = "✗", Color = THEME.ERROR_COLOR },
	warning = { Icon = "⚠", Color = THEME.WARNING_COLOR }
}

-- UI Animation Helper Module
local UIAnimation = {}

function UIAnimation.AnimateOpen(frame)
	if not frame then return end
	frame.Visible = true
	frame.Size = UDim2.new(frame.Size.X.Scale * 0.8, frame.Size.X.Offset * 0.8, frame.Size.Y.Scale * 0.8, frame.Size.Y.Offset * 0.8)
	frame.BackgroundTransparency = 1
	
	local targetSize = UDim2.new(frame.Size.X.Scale / 0.8, frame.Size.X.Offset / 0.8, frame.Size.Y.Scale / 0.8, frame.Size.Y.Offset / 0.8)
	
	local sizeTween = TweenService:Create(frame, TweenInfo.new(ANIM.PANEL_OPEN_TIME, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
		Size = targetSize,
		BackgroundTransparency = THEME.GLASS_TRANSPARENCY
	})
	sizeTween:Play()
end

function UIAnimation.AnimateClose(frame, callback)
	if not frame then return end
	
	local closeTween = TweenService:Create(frame, TweenInfo.new(ANIM.PANEL_CLOSE_TIME, ANIM.EASING_STYLE, Enum.EasingDirection.In), {
		Size = UDim2.new(frame.Size.X.Scale * 0.8, frame.Size.X.Offset * 0.8, frame.Size.Y.Scale * 0.8, frame.Size.Y.Offset * 0.8),
		BackgroundTransparency = 1
	})
	
	closeTween.Completed:Connect(function()
		frame.Visible = false
		-- Restore original size
		frame.Size = UDim2.new(frame.Size.X.Scale / 0.8, frame.Size.X.Offset / 0.8, frame.Size.Y.Scale / 0.8, frame.Size.Y.Offset / 0.8)
		if callback then callback() end
	end)
	
	closeTween:Play()
end

function UIAnimation.AnimateHover(element, isHovering)
	if not element then return end
	
	local originalSize = element:GetAttribute("OriginalSize") or element.Size
	local originalColor = element:GetAttribute("OriginalColor") or element.BackgroundColor3
	
	if isHovering then
		local hoverSize = UDim2.new(originalSize.X.Scale * ANIM.HOVER_SCALE, originalSize.X.Offset * ANIM.HOVER_SCALE, originalSize.Y.Scale * ANIM.HOVER_SCALE, originalSize.Y.Offset * ANIM.HOVER_SCALE)
		local brighterColor = Color3.new(
			math.min(originalColor.R * ANIM.HOVER_BRIGHTNESS, 1),
			math.min(originalColor.G * ANIM.HOVER_BRIGHTNESS, 1),
			math.min(originalColor.B * ANIM.HOVER_BRIGHTNESS, 1)
		)
		
		TweenService:Create(element, TweenInfo.new(0.15, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
			Size = hoverSize,
			BackgroundColor3 = brighterColor
		}):Play()
	else
		TweenService:Create(element, TweenInfo.new(0.15, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
			Size = originalSize,
			BackgroundColor3 = originalColor
		}):Play()
	end
end

function UIAnimation.AnimatePress(element)
	if not element then return end
	
	local originalSize = element:GetAttribute("OriginalSize") or element.Size
	local pressedSize = UDim2.new(originalSize.X.Scale * ANIM.CLICK_SCALE, originalSize.X.Offset * ANIM.CLICK_SCALE, originalSize.Y.Scale * ANIM.CLICK_SCALE, originalSize.Y.Offset * ANIM.CLICK_SCALE)
	
	local pressTween = TweenService:Create(element, TweenInfo.new(ANIM.CLICK_DURATION, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
		Size = pressedSize
	})
	pressTween:Play()
	
	pressTween.Completed:Connect(function()
		TweenService:Create(element, TweenInfo.new(ANIM.CLICK_DURATION, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
			Size = originalSize
		}):Play()
	end)
end

function UIAnimation.SlideIn(element, direction, duration)
	if not element then return end
	duration = duration or ANIM.NOTIFICATION_SLIDE_TIME
	
	local originalPos = element.Position
	local startOffset = 100
	
	if direction == "right" then
		element.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + startOffset, originalPos.Y.Scale, originalPos.Y.Offset)
	elseif direction == "left" then
		element.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset - startOffset, originalPos.Y.Scale, originalPos.Y.Offset)
	elseif direction == "top" then
		element.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset - startOffset)
	elseif direction == "bottom" then
		element.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset + startOffset)
	end
	
	TweenService:Create(element, TweenInfo.new(duration, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
		Position = originalPos
	}):Play()
end

function UIAnimation.SlideOut(element, direction, duration, callback)
	if not element then return end
	duration = duration or ANIM.NOTIFICATION_SLIDE_TIME
	
	local originalPos = element.Position
	local endOffset = 100
	local targetPos
	
	if direction == "right" then
		targetPos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + endOffset, originalPos.Y.Scale, originalPos.Y.Offset)
	elseif direction == "left" then
		targetPos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset - endOffset, originalPos.Y.Scale, originalPos.Y.Offset)
	elseif direction == "top" then
		targetPos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset - endOffset)
	else
		targetPos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset + endOffset)
	end
	
	local tween = TweenService:Create(element, TweenInfo.new(duration, ANIM.EASING_STYLE, Enum.EasingDirection.In), {
		Position = targetPos
	})
	
	if callback then
		tween.Completed:Connect(callback)
	end
	
	tween:Play()
end

function UIController.new()
	local self = setmetatable({}, UIController)
	
	self.Player = Players.LocalPlayer
	self.Maid = Maid.new()
	self.ScreenGui = nil
	self.MainHUD = nil
	
	-- UI State
	self.NotificationStack = {}
	self.NotificationYOffset = 20
	self.CurrentGoldDisplay = 0
	
	-- References
	self.HealthBar = nil
	self.HealthLabel = nil
	self.ManaBar = nil
	self.ManaLabel = nil
	self.EquippedSpiritDisplay = nil
	self.GoldValueLabel = nil
	self.ZoneLabel = nil
	self.ShopFrame = nil
	self.BossFrame = nil
	self.BossBarFill = nil
	self.TitleCardFrame = nil
	self.NotificationContainer = nil
	
	return self
end

function UIController:Init()
	-- Simple reliable PlayerGui access with long timeout
	self.PlayerGui = self.Player:WaitForChild("PlayerGui", 30)
	
	if not self.PlayerGui then
		warn("[UIController] Failed to get PlayerGui after 30 seconds")
		return
	end
	
	print("[UIController] Initialized - PlayerGui acquired")
end

function UIController:Start()
	if not self.PlayerGui then
		warn("[UIController] Cannot start - no PlayerGui")
		return
	end
	
	-- Force HUD creation if not present
	if not self.PlayerGui:FindFirstChild("MainHUD") then
		self:CreateMainHUD()
	end
	
	-- Create notification container and other UI elements
	self:CreateNotificationContainer(self.PlayerGui:FindFirstChild("MainHUD") or self.PlayerGui)
	self:CreateBossBar(self.PlayerGui:FindFirstChild("MainHUD") or self.PlayerGui)
	self:CreateTitleCard(self.PlayerGui:FindFirstChild("MainHUD") or self.PlayerGui)
	
	-- Connect remotes
	self:ConnectRemotes()
	
	-- Show Welcome Frame after 1 second delay
	task.delay(1, function()
		self:CreateWelcomeFrame()
	end)
	
	print("[UIController] Started with Phase 39 UI fixes")
end

function UIController:CreateGlassPanel(size, position)
	local panel = Instance.new("Frame")
	panel.Size = size
	panel.Position = position
	panel.BackgroundColor3 = THEME.PANEL_COLOR
	panel.BackgroundTransparency = THEME.GLASS_TRANSPARENCY
	panel.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = THEME.CORNER_RADIUS
	corner.Parent = panel
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.STROKE_COLOR
	stroke.Transparency = 0.5
	stroke.Thickness = 1
	stroke.Parent = panel
	
	return panel
end

function UIController:CreateActionButton(text, position, color)
	color = color or THEME.ACCENT_COLOR
	
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 120, 0, 40)
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = THEME.TEXT_COLOR
	button.Font = THEME.FONT
	button.TextSize = 16
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	
	self:ApplyButtonEffects(button, button.Size)
	
	return button
end

function UIController:CreateMainHUD()
	-- Create ScreenGui for MainHUD
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = self.PlayerGui
	self.ScreenGui = screenGui
	
	local hudFrame = Instance.new("Frame")
	hudFrame.Name = "HUDFrame"
	hudFrame.Size = UDim2.new(1, 0, 1, 0)
	hudFrame.BackgroundTransparency = 1
	hudFrame.Parent = screenGui
	self.MainHUD = hudFrame
	
	-- Top-center: Zone Label
	local zoneLabel = Instance.new("TextLabel")
	zoneLabel.Name = "ZoneLabel"
	zoneLabel.Size = UDim2.new(0, 300, 0, 40)
	zoneLabel.Position = UDim2.new(0.5, -150, 0.02, 0)
	zoneLabel.AnchorPoint = Vector2.new(0, 0)
	zoneLabel.BackgroundTransparency = 1
	zoneLabel.Text = "🏠 Hub Zone"
	zoneLabel.TextColor3 = THEME.TEXT_COLOR
	zoneLabel.TextStrokeTransparency = 0.5
	zoneLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	zoneLabel.Font = THEME.FONT
	zoneLabel.TextSize = 24
	zoneLabel.Parent = hudFrame
	self.ZoneLabel = zoneLabel
	
	-- Left-center: Quest Frame (Glassmorphism)
	local questFrame = self:CreateGlassPanel(UDim2.new(0, 250, 0, 150), UDim2.new(0, 20, 0.4, 0))
	questFrame.Name = "QuestFrame"
	questFrame.Parent = hudFrame
	
	local questTitle = Instance.new("TextLabel")
	questTitle.Name = "QuestTitle"
	questTitle.Size = UDim2.new(1, -20, 0, 30)
	questTitle.Position = UDim2.new(0, 10, 0, 10)
	questTitle.BackgroundTransparency = 1
	questTitle.Text = "📜 Active Quest"
	questTitle.TextColor3 = THEME.ACCENT_COLOR
	questTitle.Font = THEME.FONT
	questTitle.TextSize = 16
	questTitle.TextXAlignment = Enum.TextXAlignment.Left
	questTitle.Parent = questFrame
	
	local questDesc = Instance.new("TextLabel")
	questDesc.Name = "QuestDesc"
	questDesc.Size = UDim2.new(1, -20, 0, 80)
	questDesc.Position = UDim2.new(0, 10, 0, 45)
	questDesc.BackgroundTransparency = 1
	questDesc.Text = "Head North to the Glitch Wastes Gate!"
	questDesc.TextColor3 = THEME.TEXT_COLOR
	questDesc.Font = Enum.Font.Gotham
	questDesc.TextSize = 14
	questDesc.TextWrapped = true
	questDesc.TextXAlignment = Enum.TextXAlignment.Left
	questDesc.TextYAlignment = Enum.TextYAlignment.Top
	questDesc.Parent = questFrame
	
	self.QuestFrame = questFrame
	
	-- Bottom-right: Action Panel (Mobile-friendly buttons)
	local actionPanel = Instance.new("Frame")
	actionPanel.Name = "ActionPanel"
	actionPanel.Size = UDim2.new(0, 160, 0, 200)
	actionPanel.Position = UDim2.new(1, -180, 1, -220)
	actionPanel.BackgroundColor3 = THEME.PANEL_COLOR
	actionPanel.BackgroundTransparency = THEME.GLASS_TRANSPARENCY
	actionPanel.BorderSizePixel = 0
	actionPanel.Parent = hudFrame
	
	local actionCorner = Instance.new("UICorner")
	actionCorner.CornerRadius = THEME.CORNER_RADIUS
	actionCorner.Parent = actionPanel
	
	local actionStroke = Instance.new("UIStroke")
	actionStroke.Color = THEME.STROKE_COLOR
	actionStroke.Transparency = 0.5
	actionStroke.Thickness = 1
	actionStroke.Parent = actionPanel
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = actionPanel
	
	-- Attack button
	local attackBtn = self:CreateActionButton("⚔️ Attack", UDim2.new(0, 0, 0, 0), THEME.ACCENT_COLOR)
	attackBtn.Size = UDim2.new(0, 140, 0, 50)
	attackBtn.LayoutOrder = 1
	attackBtn.Parent = actionPanel
	
	-- Skill button
	local skillBtn = self:CreateActionButton("✨ Skill", UDim2.new(0, 0, 0, 0), THEME.ACCENT_SECONDARY)
	skillBtn.Size = UDim2.new(0, 140, 0, 50)
	skillBtn.LayoutOrder = 2
	skillBtn.Parent = actionPanel
	
	-- Items button
	local itemsBtn = self:CreateActionButton("🎒 Items", UDim2.new(0, 0, 0, 0), Color3.fromRGB(80, 150, 80))
	itemsBtn.Size = UDim2.new(0, 140, 0, 50)
	itemsBtn.LayoutOrder = 3
	itemsBtn.Parent = actionPanel
	
	self.ActionPanel = actionPanel
	
	-- Top-left: Health and Mana bars
	self:CreateHealthBar(hudFrame)
	self:CreateManaBar(hudFrame)
	
	-- Top-right: Currency display
	self:CreateCurrencyDisplay(hudFrame)
	
	-- Bottom-left: Equipped Spirit
	self:CreateEquippedSpiritDisplay(hudFrame)
	
	print("[UIController] Created MainHUD with ZoneLabel, QuestFrame, and ActionPanel")
end

function UIController:CreateActionButtonsPanel(parent)
	local actionPanel = Instance.new("Frame")
	actionPanel.Name = "ActionButtons"
	actionPanel.Size = UDim2.new(0, 150, 0, 180)
	actionPanel.Position = UDim2.new(1, -170, 1, -200)
	actionPanel.BackgroundTransparency = 1
	actionPanel.Parent = parent
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Parent = actionPanel
	
	-- Attack button
	local attackBtn = self:CreateActionButton("⚔️ Attack", UDim2.new(0, 0, 0, 0), THEME.ACCENT_COLOR)
	attackBtn.Size = UDim2.new(0, 140, 0, 50)
	attackBtn.LayoutOrder = 1
	attackBtn.Parent = actionPanel
	
	-- Skill button
	local skillBtn = self:CreateActionButton("✨ Skill", UDim2.new(0, 0, 0, 0), THEME.ACCENT_SECONDARY)
	skillBtn.Size = UDim2.new(0, 140, 0, 50)
	skillBtn.LayoutOrder = 2
	skillBtn.Parent = actionPanel
	
	-- Inventory button
	local inventoryBtn = self:CreateActionButton("🎒 Items", UDim2.new(0, 0, 0, 0), Color3.fromRGB(80, 150, 80))
	inventoryBtn.Size = UDim2.new(0, 140, 0, 50)
	inventoryBtn.LayoutOrder = 3
	inventoryBtn.Parent = actionPanel
	
	self.ActionButtonsPanel = actionPanel
end

function UIController:CreateWelcomeFrame()
	if not self.PlayerGui then return end
	
	local parent = self.PlayerGui:FindFirstChild("MainHUD") or self.PlayerGui
	
	-- Black Glassmorphism Center Screen Modal
	local welcomeFrame = Instance.new("Frame")
	welcomeFrame.Name = "WelcomeFrame"
	welcomeFrame.Size = UDim2.new(0, 500, 0, 350)
	welcomeFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
	welcomeFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	welcomeFrame.BackgroundTransparency = 0.1
	welcomeFrame.BorderSizePixel = 0
	welcomeFrame.Visible = true
	welcomeFrame.ZIndex = 100
	welcomeFrame.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = welcomeFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 50, 150)
	stroke.Transparency = 0.3
	stroke.Thickness = 2
	stroke.Parent = welcomeFrame
	
	-- Title Text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -40, 0, 60)
	titleLabel.Position = UDim2.new(0, 20, 0, 40)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "THE OMNI-VERSE IS COLLAPSING."
	titleLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 28
	titleLabel.TextWrapped = true
	titleLabel.ZIndex = 101
	titleLabel.Parent = welcomeFrame
	
	-- Subtitle Text
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.Size = UDim2.new(1, -60, 0, 80)
	subtitleLabel.Position = UDim2.new(0, 30, 0, 110)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Dark energies threaten to consume all realms...\n\nOnly you can restore balance to the multiverse."
	subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
	subtitleLabel.Font = Enum.Font.Gotham
	subtitleLabel.TextSize = 18
	subtitleLabel.TextWrapped = true
	subtitleLabel.ZIndex = 101
	subtitleLabel.Parent = welcomeFrame
	
	-- Enter Button
	local enterButton = Instance.new("TextButton")
	enterButton.Name = "EnterButton"
	enterButton.Size = UDim2.new(0, 200, 0, 55)
	enterButton.Position = UDim2.new(0.5, -100, 1, -90)
	enterButton.BackgroundColor3 = Color3.fromRGB(100, 50, 180)
	enterButton.BorderSizePixel = 0
	enterButton.Text = "ENTER THE HUB"
	enterButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	enterButton.Font = Enum.Font.GothamBold
	enterButton.TextSize = 20
	enterButton.ZIndex = 101
	enterButton.Parent = welcomeFrame
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = enterButton
	
	self:ApplyButtonEffects(enterButton, enterButton.Size)
	
	-- Button click handler
	enterButton.MouseButton1Click:Connect(function()
		-- Close the welcome frame with animation
		UIAnimation.AnimateClose(welcomeFrame, function()
			welcomeFrame:Destroy()
		end)
		
		-- Fire TeleportToHub remote
		local teleportEvent = Remotes:GetEvent("TeleportToHub")
		if teleportEvent then
			teleportEvent:FireServer()
		end
	end)
end

function UIController:CreateHealthBar(parent)
	local container = self:CreateGlassPanel(UDim2.new(0, 250, 0, 40), UDim2.new(0, 20, 0, 20))
	container.Name = "HealthContainer"
	container.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 30, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = "❤️"
	label.TextSize = 20
	label.Parent = container
	
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -45, 0, 20)
	barBg.Position = UDim2.new(0, 40, 0.5, -10)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	barBg.BorderSizePixel = 0
	barBg.Parent = container
	
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 6)
	barCorner.Parent = barBg
	
	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = THEME.ERROR_COLOR
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 6)
	fillCorner.Parent = barFill
	
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, 0, 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "100/100"
	valueLabel.TextColor3 = THEME.TEXT_COLOR
	valueLabel.Font = THEME.FONT
	valueLabel.TextSize = 12
	valueLabel.Parent = barBg
	
	self.HealthBar = barFill
	self.HealthLabel = valueLabel
end

function UIController:CreateManaBar(parent)
	local container = self:CreateGlassPanel(UDim2.new(0, 250, 0, 35), UDim2.new(0, 20, 0, 65))
	container.Name = "ManaContainer"
	container.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 30, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = "💧"
	label.TextSize = 18
	label.Parent = container
	
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -45, 0, 16)
	barBg.Position = UDim2.new(0, 40, 0.5, -8)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	barBg.BorderSizePixel = 0
	barBg.Parent = container
	
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 6)
	barCorner.Parent = barBg
	
	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = THEME.ACCENT_COLOR
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 6)
	fillCorner.Parent = barFill
	
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, 0, 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "100/100"
	valueLabel.TextColor3 = THEME.TEXT_COLOR
	valueLabel.Font = THEME.FONT
	valueLabel.TextSize = 11
	valueLabel.Parent = barBg
	
	self.ManaBar = barFill
	self.ManaLabel = valueLabel
end

function UIController:CreateCurrencyDisplay(parent)
	local container = self:CreateGlassPanel(UDim2.new(0, 180, 0, 50), UDim2.new(1, -200, 0, 20))
	container.Name = "CurrencyDisplay"
	container.Parent = parent
	
	local goldIcon = Instance.new("TextLabel")
	goldIcon.Size = UDim2.new(0, 30, 1, 0)
	goldIcon.Position = UDim2.new(0, 10, 0, 0)
	goldIcon.BackgroundTransparency = 1
	goldIcon.Text = "🪙"
	goldIcon.TextSize = 24
	goldIcon.Parent = container
	
	local goldValue = Instance.new("TextLabel")
	goldValue.Name = "GoldValue"
	goldValue.Size = UDim2.new(1, -50, 1, 0)
	goldValue.Position = UDim2.new(0, 45, 0, 0)
	goldValue.BackgroundTransparency = 1
	goldValue.Text = "0"
	goldValue.TextColor3 = Color3.fromRGB(255, 215, 0)
	goldValue.Font = THEME.FONT
	goldValue.TextSize = 22
	goldValue.TextXAlignment = Enum.TextXAlignment.Left
	goldValue.Parent = container
	
	self.GoldValueLabel = goldValue
end

function UIController:CreateEquippedSpiritDisplay(parent)
	local container = self:CreateGlassPanel(UDim2.new(0, 200, 0, 60), UDim2.new(0, 20, 1, -80))
	container.Name = "EquippedSpirit"
	container.Parent = parent
	
	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.new(0, 50, 0, 50)
	iconFrame.Position = UDim2.new(0, 5, 0.5, -25)
	iconFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = container
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconFrame
	
	local spiritIcon = Instance.new("TextLabel")
	spiritIcon.Name = "Icon"
	spiritIcon.Size = UDim2.new(1, 0, 1, 0)
	spiritIcon.BackgroundTransparency = 1
	spiritIcon.Text = "👻"
	spiritIcon.TextSize = 30
	spiritIcon.Parent = iconFrame
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "SpiritName"
	nameLabel.Size = UDim2.new(1, -65, 0, 20)
	nameLabel.Position = UDim2.new(0, 60, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "No Spirit"
	nameLabel.TextColor3 = THEME.TEXT_COLOR
	nameLabel.Font = THEME.FONT
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = container
	
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "SpiritLevel"
	levelLabel.Size = UDim2.new(1, -65, 0, 16)
	levelLabel.Position = UDim2.new(0, 60, 0, 30)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Lv. --"
	levelLabel.TextColor3 = THEME.TEXT_MUTED
	levelLabel.Font = THEME.FONT
	levelLabel.TextSize = 12
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Parent = container
	
	self.EquippedSpiritDisplay = container
end

function UIController:CreateZoneDisplay(parent)
	local container = Instance.new("Frame")
	container.Name = "ZoneDisplay"
	container.Size = UDim2.new(0, 300, 0, 40)
	container.Position = UDim2.new(0.5, -150, 0, 20)
	container.BackgroundTransparency = 1
	container.Parent = parent
	
	local zoneLabel = Instance.new("TextLabel")
	zoneLabel.Name = "ZoneName"
	zoneLabel.Size = UDim2.new(1, 0, 1, 0)
	zoneLabel.BackgroundTransparency = 1
	zoneLabel.Text = "🏠 Hub Zone"
	zoneLabel.TextColor3 = THEME.TEXT_COLOR
	zoneLabel.TextStrokeTransparency = 0.5
	zoneLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	zoneLabel.Font = THEME.FONT
	zoneLabel.TextSize = 20
	zoneLabel.Parent = container
	
	self.ZoneLabel = zoneLabel
end

function UIController:UpdateHealthBar(current, max)
	if not self.HealthBar then return end
	
	local percent = math.clamp(current / max, 0, 1)
	
	TweenService:Create(self.HealthBar, TweenInfo.new(ANIM.BAR_TRANSITION_TIME, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
		Size = UDim2.new(percent, 0, 1, 0)
	}):Play()
	
	if self.HealthLabel then
		self.HealthLabel.Text = math.floor(current) .. "/" .. math.floor(max)
	end
end

function UIController:UpdateManaBar(current, max)
	if not self.ManaBar then return end
	
	local percent = math.clamp(current / max, 0, 1)
	
	TweenService:Create(self.ManaBar, TweenInfo.new(ANIM.BAR_TRANSITION_TIME, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
		Size = UDim2.new(percent, 0, 1, 0)
	}):Play()
	
	if self.ManaLabel then
		self.ManaLabel.Text = math.floor(current) .. "/" .. math.floor(max)
	end
end

function UIController:UpdateGoldWithAnimation(newGold, previousGold)
	if not self.GoldValueLabel then return end
	
	local startGold = previousGold or self.CurrentGoldDisplay
	local endGold = newGold
	local duration = ANIM.GOLD_INCREMENT_TIME
	local elapsed = 0
	
	-- Animate counting up/down
	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
		elapsed = elapsed + dt
		local progress = math.min(elapsed / duration, 1)
		local eased = 1 - math.pow(1 - progress, 3) -- Cubic ease out
		
		local displayValue = math.floor(startGold + (endGold - startGold) * eased)
		self.GoldValueLabel.Text = tostring(displayValue)
		
		if progress >= 1 then
			connection:Disconnect()
			self.CurrentGoldDisplay = endGold
		end
	end)
	
	-- Flash effect for gold gain
	if endGold > startGold then
		TweenService:Create(self.GoldValueLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, true), {
			TextColor3 = Color3.fromRGB(255, 255, 150)
		}):Play()
	end
end

function UIController:UpdateEquippedSpirit(spiritData)
	if not self.EquippedSpiritDisplay then return end
	
	local iconLabel = self.EquippedSpiritDisplay:FindFirstChild("Icon", true)
	local nameLabel = self.EquippedSpiritDisplay:FindFirstChild("SpiritName")
	local levelLabel = self.EquippedSpiritDisplay:FindFirstChild("SpiritLevel")
	
	if spiritData then
		if nameLabel then nameLabel.Text = spiritData.Name or "Unknown Spirit" end
		if levelLabel then levelLabel.Text = "Lv. " .. (spiritData.Level or 1) end
		if iconLabel then iconLabel.Text = spiritData.Icon or "👻" end
	else
		if nameLabel then nameLabel.Text = "No Spirit" end
		if levelLabel then levelLabel.Text = "Lv. --" end
		if iconLabel then iconLabel.Text = "👻" end
	end
end

function UIController:UpdateZoneDisplay(zoneName)
	if not self.ZoneLabel then return end
	
	self.ZoneLabel.TextTransparency = 1
	self.ZoneLabel.Text = "📍 " .. zoneName
	
	TweenService:Create(self.ZoneLabel, TweenInfo.new(0.5, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
		TextTransparency = 0
	}):Play()
end

function UIController:CreateContextButtons(parent)
	local frame = Instance.new("Frame")
	frame.Name = "ContextButtons"
	frame.Size = UDim2.new(0, 60, 0, 100)
	frame.Position = UDim2.new(1, -80, 0.5, -50)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	
	local boatBtn = self:CreateActionButton("⛵", UDim2.new(0, 0, 0, 0), Color3.fromRGB(50, 100, 200))
	boatBtn.Size = UDim2.new(0, 50, 0, 50)
	boatBtn.LayoutOrder = 1
	boatBtn.Visible = false
	boatBtn.Parent = frame
	self.BoatButton = boatBtn
end

function UIController:CreateBossBar(parent)
	local frame = self:CreateGlassPanel(UDim2.new(0.5, 0, 0, 50), UDim2.new(0.25, 0, 0, 60))
	frame.Name = "BossBar"
	frame.Visible = false
	frame.Parent = parent
	self.BossFrame = frame
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "BOSS NAME"
	nameLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	nameLabel.Font = THEME.FONT
	nameLabel.TextSize = 16
	nameLabel.Parent = frame
	self.BossNameLabel = nameLabel
	
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(0.9, 0, 0, 20)
	barBg.Position = UDim2.new(0.05, 0, 0.5, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	barBg.BorderSizePixel = 0
	barBg.Parent = frame
	
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 4)
	barCorner.Parent = barBg
	
	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = barFill
	self.BossBarFill = barFill
end

function UIController:ShowBossBar(data)
	if not self.BossFrame then return end
	self.BossFrame.Visible = true
	self.BossNameLabel.Text = data.Name or "BOSS"
	self.BossBarFill.Size = UDim2.new(1, 0, 1, 0)
end

function UIController:UpdateBossBar(current, max)
	if not self.BossBarFill then return end
	local percent = math.clamp(current / max, 0, 1)
	TweenService:Create(self.BossBarFill, TweenInfo.new(0.3, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
		Size = UDim2.new(percent, 0, 1, 0)
	}):Play()
end

function UIController:HideBossBar()
	if self.BossFrame then
		self.BossFrame.Visible = false
	end
end

function UIController:CreateTitleCard(parent)
	local frame = Instance.new("Frame")
	frame.Name = "TitleCard"
	frame.Size = UDim2.new(1, 0, 0, 100)
	frame.Position = UDim2.new(0, 0, 0.3, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = parent
	self.TitleCardFrame = frame
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "BOSS NAME"
	label.TextColor3 = THEME.TEXT_COLOR
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Font = THEME.FONT
	label.TextSize = 48
	label.Parent = frame
	self.TitleLabel = label
end

function UIController:ShowTitleCard(text)
	if not self.TitleCardFrame then return end
	
	self.TitleLabel.Text = text
	self.TitleCardFrame.Visible = true
	self.TitleLabel.TextTransparency = 1
	
	TweenService:Create(self.TitleLabel, TweenInfo.new(0.5, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
		TextTransparency = 0
	}):Play()
	
	task.delay(3, function()
		TweenService:Create(self.TitleLabel, TweenInfo.new(0.5, ANIM.EASING_STYLE, Enum.EasingDirection.In), {
			TextTransparency = 1
		}):Play()
		task.delay(0.5, function()
			self.TitleCardFrame.Visible = false
		end)
	end)
end

function UIController:CreateNotificationContainer(parent)
	local container = Instance.new("Frame")
	container.Name = "NotificationContainer"
	container.Size = UDim2.new(0, 300, 1, 0)
	container.Position = UDim2.new(1, -320, 0, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent
	self.NotificationContainer = container
end

function UIController:ShowNotification(message, notificationType, duration)
	notificationType = notificationType or "info"
	duration = duration or 4
	
	local typeData = NOTIFICATION_TYPES[notificationType] or NOTIFICATION_TYPES.info
	
	local notification = self:CreateGlassPanel(UDim2.new(1, 0, 0, 60), UDim2.new(1.2, 0, 0, self.NotificationYOffset))
	notification.Name = "Notification"
	notification.Parent = self.NotificationContainer
	
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 40, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = typeData.Icon
	icon.TextSize = 24
	icon.Parent = notification
	
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -50, 1, 0)
	text.Position = UDim2.new(0, 45, 0, 0)
	text.BackgroundTransparency = 1
	text.Text = message
	text.TextColor3 = THEME.TEXT_COLOR
	text.Font = THEME.FONT
	text.TextSize = 14
	text.TextWrapped = true
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Parent = notification
	
	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 4, 1, 0)
	accent.BackgroundColor3 = typeData.Color
	accent.BorderSizePixel = 0
	accent.Parent = notification
	
	table.insert(self.NotificationStack, notification)
	self.NotificationYOffset = self.NotificationYOffset + 70
	
	UIAnimation.SlideIn(notification, "right", 0.3)
	
	task.delay(duration, function()
		UIAnimation.SlideOut(notification, "right", 0.25, function()
			local index = table.find(self.NotificationStack, notification)
			if index then
				table.remove(self.NotificationStack, index)
				self.NotificationYOffset = self.NotificationYOffset - 70
				
				for i, notif in ipairs(self.NotificationStack) do
					TweenService:Create(notif, TweenInfo.new(0.2, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
						Position = UDim2.new(0, 0, 0, 20 + ((i - 1) * 70))
					}):Play()
				end
			end
			notification:Destroy()
		end)
	end)
end

function UIController:ShowPurchaseFeedback(success, resultCode, itemName, cost)
	if success then
		self:ShowNotification("✓ Purchased " .. (itemName or "item") .. "!", "success", 3)
		
		if self.GoldValueLabel then
			TweenService:Create(self.GoldValueLabel, TweenInfo.new(0.2, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION, 0, true, 0.1), {
				TextColor3 = Color3.fromRGB(100, 255, 100)
			}):Play()
		end
	else
		if resultCode == "INSUFFICIENT_FUNDS" then
			self:ShowNotification("✗ Not enough Gold!", "error", 3)
			self:ShakePanel(self.ShopFrame)
			self:FlashRedTint(self.ShopFrame)
		elseif resultCode == "ALREADY_OWNED" then
			self:ShowNotification("✗ Already owned!", "warning", 3)
		else
			self:ShowNotification("✗ Purchase failed", "error", 3)
		end
	end
end

function UIController:ShakePanel(panel)
	if not panel then return end
	
	local originalPos = panel.Position
	local shakeAmount = 5
	local shakeDuration = 0.4
	local shakeCount = 6
	
	for i = 1, shakeCount do
		local offsetX = (math.random() - 0.5) * shakeAmount * 2
		local offsetY = (math.random() - 0.5) * shakeAmount * 2
		
		TweenService:Create(panel, TweenInfo.new(shakeDuration / shakeCount, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + offsetX, originalPos.Y.Scale, originalPos.Y.Offset + offsetY)
		}):Play()
		task.wait(shakeDuration / shakeCount)
	end
	
	TweenService:Create(panel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = originalPos
	}):Play()
end

function UIController:FlashRedTint(panel)
	if not panel then return end
	
	local overlay = Instance.new("Frame")
	overlay.Name = "RedFlash"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	overlay.BackgroundTransparency = 0.7
	overlay.ZIndex = 10
	overlay.Parent = panel
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = THEME.CORNER_RADIUS
	corner.Parent = overlay
	
	TweenService:Create(overlay, TweenInfo.new(0.3, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
		BackgroundTransparency = 1
	}):Play()
	
	task.delay(0.3, function()
		if overlay then overlay:Destroy() end
	end)
end

function UIController:ApplyButtonEffects(button, originalSize)
	button:SetAttribute("OriginalSize", originalSize)
	button:SetAttribute("OriginalColor", button.BackgroundColor3)
	
	button.MouseEnter:Connect(function()
		UIAnimation.AnimateHover(button, true)
	end)
	
	button.MouseLeave:Connect(function()
		UIAnimation.AnimateHover(button, false)
	end)
	
	button.MouseButton1Down:Connect(function()
		UIAnimation.AnimatePress(button)
	end)
end

function UIController:ConnectRemotes()
	-- Connect to remote events for UI updates
	local updateHealth = Remotes:GetEvent("UpdateHealth")
	if updateHealth then
		updateHealth.OnClientEvent:Connect(function(current, max)
			self:UpdateHealthBar(current, max)
		end)
	end
	
	local updateMana = Remotes:GetEvent("UpdateMana")
	if updateMana then
		updateMana.OnClientEvent:Connect(function(current, max)
			self:UpdateManaBar(current, max)
		end)
	end
	
	local updateGold = Remotes:GetEvent("UpdateGold")
	if updateGold then
		updateGold.OnClientEvent:Connect(function(newGold)
			local prev = self.CurrentGoldDisplay
			self:UpdateGoldWithAnimation(newGold, prev)
		end)
	end
	
	local zoneChanged = Remotes:GetEvent("ZoneChanged")
	if zoneChanged then
		zoneChanged.OnClientEvent:Connect(function(zoneName)
			self:UpdateZoneDisplay(zoneName)
		end)
	end
	
	local notification = Remotes:GetEvent("ShowNotification")
	if notification then
		notification.OnClientEvent:Connect(function(message, notifType, duration)
			self:ShowNotification(message, notifType, duration)
		end)
	end
	
	local bossSpawn = Remotes:GetEvent("BossSpawned")
	if bossSpawn then
		bossSpawn.OnClientEvent:Connect(function(bossData)
			self:ShowBossBar(bossData)
			self:ShowTitleCard(bossData.Name or "BOSS")
		end)
	end
	
	local bossHealth = Remotes:GetEvent("BossHealthUpdate")
	if bossHealth then
		bossHealth.OnClientEvent:Connect(function(current, max)
			self:UpdateBossBar(current, max)
		end)
	end
	
	local bossDead = Remotes:GetEvent("BossDefeated")
	if bossDead then
		bossDead.OnClientEvent:Connect(function()
			self:HideBossBar()
		end)
	end
end

function UIController:Cleanup()
	self.Maid:Cleanup()
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
end

return UIController
