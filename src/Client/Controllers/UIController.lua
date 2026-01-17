--[[

	UIController.lua
	Manages the main HUD and UI updates.

]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maid = require(Shared.Modules.Maid)
local Signal = require(Shared.Modules.Signal)
local Remotes = require(Shared.Remotes)
local Constants = require(Shared.Modules.Constants)

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
	GLASS_TRANSPARENCY = 0.4,
	ACCENT_COLOR = Color3.fromRGB(0, 170, 255),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	FONT = Enum.Font.GothamBold,
	CORNER_RADIUS = UDim.new(0, 12)
}

-- Standardized Animation Timing
local ANIM = {
	PANEL_OPEN_TIME = 0.35,
	PANEL_CLOSE_TIME = 0.25,
	BUTTON_HOVER_TIME = 0.15,
	BUTTON_CLICK_TIME = 0.08,
	HOVER_SCALE = 1.1,
	CLICK_SCALE = 0.9,
	EASING_STYLE = Enum.EasingStyle.Quad,
	EASING_DIRECTION = Enum.EasingDirection.Out,
}

function UIController:Init()
	self.Player = Players.LocalPlayer
	self.PlayerGui = self.Player:WaitForChild("PlayerGui", 30)
	
	if not self.PlayerGui then
		warn("[UIController] PlayerGui not found after 30 seconds!")
		return
	end
	
	self.RequestSkill = Remotes.GetEvent("RequestSkill")
	self.TeleportToHub = Remotes.GetEvent("TeleportToHub")
	self.SpawnVehicle = Remotes.GetEvent("SpawnVehicle")
	self.PurchaseItemFunc = Remotes.GetFunction("PurchaseItem")
	
	-- Gold Update Event
	local GoldUpdate = Remotes.GetEvent("GoldUpdate")
	GoldUpdate.OnClientEvent:Connect(function(newGold)
		self:UpdateGoldDisplay(newGold)
	end)
	
	-- Boss Events
	local BossSpawned = Remotes.GetEvent("BossSpawned")
	local BossUpdate = Remotes.GetEvent("BossUpdate")
	local BossDefeated = Remotes.GetEvent("BossDefeated")
	local QuestUpdate = Remotes.GetEvent("QuestUpdate")
	
	BossSpawned.OnClientEvent:Connect(function(data)
		self:ShowBossBar(data)
		self:ShowTitleCard(data.Name)
	end)
	
	BossUpdate.OnClientEvent:Connect(function(current, max)
		self:UpdateBossBar(current, max)
	end)
	
	BossDefeated.OnClientEvent:Connect(function()
		self:HideBossBar()
	end)
	
	-- Announcement Event
	local Announcement = Remotes.GetEvent("Announcement")
	Announcement.OnClientEvent:Connect(function(message, color)
		self:DisplayAnnouncement(message, color)
	end)
	
	QuestUpdate.OnClientEvent:Connect(function(data)
		self:UpdateQuestTracker(data)
	end)
	
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
	
	-- Show Welcome Popup
	self:ShowWelcomePopup()
	
	-- Zone Check Loop
	task.spawn(function()
		while true do
			self:UpdateZoneDisplay()
			task.wait(0.5)
		end
	end)
end

function UIController:CreateHUD()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = self.PlayerGui
	self.ScreenGui = screenGui
	
	-- 0. Zone Display (Top Center)
	self:CreateZoneLabel(screenGui)
	
	-- 1. Currency Panel (Top Left)
	local currencyFrame = self:CreateGlassPanel(UDim2.new(0, 220, 0, 115), UDim2.new(0, 20, 0, 20))
	currencyFrame.Name = "CurrencyPanel"
	currencyFrame.Parent = screenGui
	
	self.GoldLabel = self:CreateCurrencyLabel("Gold", "🪙", 0, currencyFrame)
	self.EssenceLabel = self:CreateCurrencyLabel("Essence", "✨", 1, currencyFrame)
	self.AetherLabel = self:CreateCurrencyLabel("Aether", "💎", 2, currencyFrame)
	self.CrystalsLabel = self:CreateCurrencyLabel("Crystals", "🔮", 3, currencyFrame)
	
	-- 1.5 Menu Buttons (Left Side)
	self:CreateMenuButtons(screenGui)
	
	-- 1.55 Shop UI
	self:CreateShopUI(screenGui)
	
	-- 1.6 Context Buttons (Right Side, above combat)
	self:CreateContextButtons(screenGui)
	
	-- 1.8 Boss Bar (Hidden by default)
	self:CreateBossBar(screenGui)
	
	-- 1.9 Title Card (Hidden by default)
	self:CreateTitleCard(screenGui)
	
	-- 1.95 Quest Tracker
	self:CreateQuestTracker(screenGui)
	
	-- 1.98 Subtitles
	self:CreateSubtitleFrame(screenGui)
	
	-- 1.99 Dialogue Frame
	self:CreateDialogueFrame(screenGui)
	
	-- 2.0 Bottom Center HUD (Health & Essence)
	self:CreateBottomHUD(screenGui)

	-- 2. Combat Controls (Bottom Right) - Mobile/Action Buttons
	-- Using Glassmorphism as requested
	local combatFrame = self:CreateGlassPanel(UDim2.new(0, 250, 0, 250), UDim2.new(1, -20, 1, -20))
	combatFrame.Name = "CombatControls"
	combatFrame.AnchorPoint = Vector2.new(1, 1)
	combatFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	combatFrame.BackgroundTransparency = 0.3
	combatFrame.Parent = screenGui
	
	-- Attack Button (Large)
	local attackBtn = self:CreateActionButton("⚔️", UDim2.new(1, -10, 1, -10), Color3.fromRGB(255, 80, 80))
	attackBtn.Size = UDim2.new(0, 90, 0, 90)
	attackBtn.AnchorPoint = Vector2.new(1, 1)
	attackBtn.Parent = combatFrame
	
	-- Ability 1 (Left of Attack)
	local ability1Btn = self:CreateActionButton("1", UDim2.new(1, -110, 1, -10), THEME.ACCENT_COLOR)
	ability1Btn.Size = UDim2.new(0, 70, 0, 70)
	ability1Btn.AnchorPoint = Vector2.new(1, 1)
	ability1Btn.Parent = combatFrame
	
	ability1Btn.Activated:Connect(function()
		self:UseSkill("Fireball")
	end)
	
	-- Ability 2 (Above Attack)
	local ability2Btn = self:CreateActionButton("2", UDim2.new(1, -10, 1, -110), THEME.ACCENT_COLOR)
	ability2Btn.Size = UDim2.new(0, 70, 0, 70)
	ability2Btn.AnchorPoint = Vector2.new(1, 1)
	ability2Btn.Parent = combatFrame
	
	ability2Btn.Activated:Connect(function()
		self:UseSkill("Dash")
	end)
	
	-- Bind Actions
	attackBtn.Activated:Connect(function()
		self:OnAttackPressed()
	end)
	
	-- ContextActionService Binding
	local function handleAction(actionName, inputState, inputObject)
		if inputState == Enum.UserInputState.Begin then
			if actionName == "Attack" then
				self:OnAttackPressed()
			elseif actionName == "Skill1" then
				self:UseSkill("Fireball")
			elseif actionName == "Skill2" then
				self:UseSkill("Dash")
			end
		end
	end

	local attackInputs = {Enum.KeyCode.Space, Enum.KeyCode.ButtonR2}
	-- Only bind MouseButton1 if not on mobile to prevent conflict with camera rotation
	if not UserInputService.TouchEnabled then
		table.insert(attackInputs, Enum.UserInputType.MouseButton1)
	end

	ContextActionService:BindAction("Attack", handleAction, false, unpack(attackInputs))
	ContextActionService:BindAction("Skill1", handleAction, false, Enum.KeyCode.One, Enum.KeyCode.ButtonX)
	ContextActionService:BindAction("Skill2", handleAction, false, Enum.KeyCode.Two, Enum.KeyCode.ButtonY)
end

function UIController:CreateBottomHUD(parent)
	local frame = self:CreateGlassPanel(UDim2.new(0, 300, 0, 80), UDim2.new(0.5, -150, 1, -100))
	frame.Name = "BottomHUD"
	frame.Parent = parent
	self.BottomHUDFrame = frame

	-- Health Bar Background
	local healthBg = Instance.new("Frame")
	healthBg.Name = "HealthBg"
	healthBg.Size = UDim2.new(0.9, 0, 0, 20)
	healthBg.Position = UDim2.new(0.05, 0, 0.2, 0)
	healthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = frame
	
	local healthCorner = Instance.new("UICorner")
	healthCorner.CornerRadius = UDim.new(0, 4)
	healthCorner.Parent = healthBg

	-- Health Bar Fill
	local healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100) -- Green
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBg
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = healthFill
	self.HealthBarFill = healthFill

	-- Essence Label
	local essenceLabel = Instance.new("TextLabel")
	essenceLabel.Name = "EssenceLabel"
	essenceLabel.Size = UDim2.new(1, 0, 0, 30)
	essenceLabel.Position = UDim2.new(0, 0, 0.5, 0)
	essenceLabel.BackgroundTransparency = 1
	essenceLabel.Text = "Essence: 0"
	essenceLabel.TextColor3 = THEME.TEXT_COLOR
	essenceLabel.Font = THEME.FONT
	essenceLabel.TextSize = 20
	essenceLabel.Parent = frame
	self.BottomEssenceLabel = essenceLabel

	-- Connect Health Update
	local humanoid = self.Player.Character and self.Player.Character:FindFirstChild("Humanoid")
	if humanoid then
		self:UpdateHealth(humanoid)
		humanoid.HealthChanged:Connect(function()
			self:UpdateHealth(humanoid)
		end)
	end
	
	self.Player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		self:UpdateHealth(hum)
		hum.HealthChanged:Connect(function()
			self:UpdateHealth(hum)
		end)
	end)
end

function UIController:UpdateHealth(humanoid)
	if not self.HealthBarFill then return end
	local percent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	self.HealthBarFill:TweenSize(UDim2.new(percent, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
end

function UIController:ShowWelcomePopup()
	local screenGui = self.ScreenGui
	if not screenGui then return end

	local frame = self:CreateGlassPanel(UDim2.new(0, 400, 0, 200), UDim2.new(0.5, -200, 0.5, -100))
	frame.Name = "WelcomePopup"
	frame.Parent = screenGui
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "Welcome to Aetheria"
	title.TextColor3 = THEME.ACCENT_COLOR
	title.Font = THEME.FONT
	title.TextSize = 28
	title.Parent = frame
	
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0.9, 0, 0.5, 0)
	desc.Position = UDim2.new(0.05, 0, 0.25, 0)
	desc.BackgroundTransparency = 1
	desc.Text = "The Omni-Verse is collapsing.\nDefeat the Glitch."
	desc.TextColor3 = THEME.TEXT_COLOR
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 18
	desc.TextWrapped = true
	desc.Parent = frame
	
	local closeBtn = self:CreateActionButton("BEGIN", UDim2.new(0.5, 0, 0.85, 0), THEME.ACCENT_COLOR)
	closeBtn.Size = UDim2.new(0, 120, 0, 40)
	closeBtn.TextSize = 18
	closeBtn.Parent = frame
	
	closeBtn.Activated:Connect(function()
		-- Tween out
		local t = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
		t:Play()
		t.Completed:Connect(function()
			frame:Destroy()
		end)
	end)
end

function UIController:CreateZoneLabel(parent)
	local frame = self:CreateGlassPanel(UDim2.new(0, 200, 0, 40), UDim2.new(0.5, -100, 0, 10))
	frame.Name = "ZoneDisplay"
	frame.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Name = "ZoneName"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "Hub"
	label.TextColor3 = THEME.ACCENT_COLOR
	label.Font = THEME.FONT
	label.TextSize = 18
	label.Parent = frame
	self.ZoneLabel = label
end

function UIController:UpdateZoneDisplay()
	if not self.Player.Character or not self.Player.Character.PrimaryPart then return end
	
	local pos = self.Player.Character.PrimaryPart.Position
	local currentZone = "Wilderness"
	
	-- Check Hub (Simple radius check)
	if pos.Magnitude < 150 then
		currentZone = "Hub"
	elseif pos.X > 5000 then
		currentZone = "Azure Sea"
	else
		-- Check defined zones
		for name, zone in pairs(Constants.ZONES) do
			local center = zone.Center
			local size = zone.Size
			
			-- Simple AABB check (ignoring Y for now or using large Y)
			if math.abs(pos.X - center.X) < size.X/2 and
			   math.abs(pos.Z - center.Z) < size.Z/2 then
				currentZone = name
				break
			end
		end
	end
	
	-- Update Label
	if self.ZoneLabel then
		local displayText = currentZone
		if currentZone == "Azure Sea" then
			displayText = "🌊 The Azure Sea (Fishing Zone)"
		end
		
		if self.ZoneLabel.Text ~= displayText then
			self.ZoneLabel.Text = displayText
			
			-- Pulse effect
			local t = TweenService:Create(self.ZoneLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {TextSize = 22})
			t:Play()
		end
	end
	
	-- Update Context Buttons
	if self.BoatButton then
		self.BoatButton.Visible = (currentZone == "Azure Sea")
	end
end

function UIController:CreateQuestTracker(parent)
	local frame = self:CreateGlassPanel(UDim2.new(0, 220, 0, 0), UDim2.new(0, 20, 0, 350)) -- Height 0 for AutomaticSize
	frame.Name = "QuestTracker"
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Visible = false
	frame.Parent = parent
	self.QuestFrame = frame
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 25)
	title.Position = UDim2.new(0, 10, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "Quest Title"
	title.TextColor3 = THEME.ACCENT_COLOR
	title.Font = THEME.FONT
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame
	self.QuestTitle = title
	
	local desc = Instance.new("TextLabel")
	desc.Name = "Description"
	desc.Size = UDim2.new(1, -20, 0, 0) -- Height 0 for AutomaticSize
	desc.AutomaticSize = Enum.AutomaticSize.Y
	desc.Position = UDim2.new(0, 10, 0, 30)
	desc.BackgroundTransparency = 1
	desc.Text = "Quest Description goes here..."
	desc.TextColor3 = THEME.TEXT_COLOR
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 12
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.Parent = frame
	self.QuestDesc = desc
	
	local tasks = Instance.new("Frame")
	tasks.Name = "Tasks"
	tasks.Size = UDim2.new(1, -20, 0, 0) -- Height 0 for AutomaticSize
	tasks.AutomaticSize = Enum.AutomaticSize.Y
	tasks.Position = UDim2.new(0, 10, 0, 0) -- Position will be adjusted by UIListLayout if we used one for the main frame, but here we manually position.
	-- Actually, let's use a UIListLayout for the main frame to make it easier.
	tasks.BackgroundTransparency = 1
	tasks.Parent = frame
	self.QuestTasks = tasks
	
	-- Main Layout
	local mainLayout = Instance.new("UIListLayout")
	mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainLayout.Padding = UDim.new(0, 5)
	mainLayout.Parent = frame
	
	-- Adjust LayoutOrders
	title.LayoutOrder = 1
	desc.LayoutOrder = 2
	tasks.LayoutOrder = 3
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = tasks
end

function UIController:CreateDialogueFrame(parent)
	local frame = self:CreateGlassPanel(UDim2.new(0.8, 0, 0, 150), UDim2.new(0.1, 0, 0.75, 0))
	frame.Name = "DialogueFrame"
	frame.Visible = false
	frame.Parent = parent
	self.DialogueFrame = frame
    
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0, 200, 0, 30)
	nameLabel.Position = UDim2.new(0, 20, 0, -15)
	nameLabel.BackgroundColor3 = THEME.ACCENT_COLOR
	nameLabel.Text = "NAME"
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Font = THEME.FONT
	nameLabel.TextSize = 18
	nameLabel.Parent = frame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = nameLabel
	self.DialogueName = nameLabel
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.Size = UDim2.new(1, -40, 1, -40)
	textLabel.Position = UDim2.new(0, 20, 0, 20)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "Dialogue text goes here..."
	textLabel.TextColor3 = THEME.TEXT_COLOR
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextSize = 20
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.Parent = frame
	self.DialogueText = textLabel
	
	-- Continue indicator
	local continueLabel = Instance.new("TextLabel")
	continueLabel.Size = UDim2.new(0, 100, 0, 20)
	continueLabel.Position = UDim2.new(1, -120, 1, -25)
	continueLabel.BackgroundTransparency = 1
	continueLabel.Text = "Click to continue..."
	continueLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	continueLabel.Font = Enum.Font.Gotham
	continueLabel.TextSize = 14
	continueLabel.Parent = frame
	
	-- Click handler
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = frame
	
	btn.Activated:Connect(function()
		if self.DialogueCallback then
			self.DialogueCallback()
		end
	end)
end

function UIController:ShowDialogue(name, text, callback)
	if not self.DialogueFrame then return end
	
	self.DialogueName.Text = name
	self.DialogueText.Text = text
	self.DialogueFrame.Visible = true
	self.DialogueCallback = callback
	
	-- Typewriter effect
	self.DialogueText.MaxVisibleGraphemes = 0
	local len = string.len(text)
	for i = 1, len do
		self.DialogueText.MaxVisibleGraphemes = i
		task.wait(0.02)
	end
end

function UIController:PlayDialogueSequence(sequence)
	-- sequence is array of {Name = "X", Text = "Y"}
	local index = 1
	
	local function showNext()
		if index > #sequence then
			self.DialogueFrame.Visible = false
			self.DialogueCallback = nil
			return
		end
		
		local data = sequence[index]
		index += 1
		
		self:ShowDialogue(data.Name, data.Text, showNext)
	end
	
	showNext()
end

function UIController:CreateSubtitleFrame(parent)
	local frame = Instance.new("Frame")
	frame.Name = "SubtitleFrame"
	frame.Size = UDim2.new(1, 0, 0, 60)
	frame.Position = UDim2.new(0, 0, 0.85, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	self.SubtitleFrame = frame
	
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.Position = UDim2.new(0.2, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = ""
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 22
	label.TextWrapped = true
	label.TextTransparency = 1
	label.TextStrokeTransparency = 1
	label.Parent = frame
	self.SubtitleLabel = label
end

function UIController:ShowSubtitle(text, duration)
	if not self.SubtitleLabel then return end
	
	self.SubtitleLabel.Text = text
	
	local t1 = TweenService:Create(self.SubtitleLabel, TweenInfo.new(0.5), {TextTransparency = 0, TextStrokeTransparency = 0})
	t1:Play()
	
	task.delay(duration or 3, function()
		if self.SubtitleLabel.Text == text then
			local t2 = TweenService:Create(self.SubtitleLabel, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1})
			t2:Play()
		end
	end)
end

function UIController:UpdateQuestTracker(data)
	if not self.QuestFrame then return end
	
	if not data then
		self.QuestFrame.Visible = false
		return
	end
	
	self.QuestFrame.Visible = true
	self.QuestTitle.Text = data.Title
	self.QuestDesc.Text = data.Description
	
	-- Clear old tasks
	for _, child in ipairs(self.QuestTasks:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	
	-- Add new tasks
	if data.Tasks then
		for i, taskData in ipairs(data.Tasks) do
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 0, 20)
			label.BackgroundTransparency = 1
			label.Text = string.format("- %s: %d/%d", taskData.Description, taskData.Current, taskData.Required)
			label.TextColor3 = THEME.TEXT_COLOR
			label.Font = Enum.Font.Gotham
			label.TextSize = 12
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.LayoutOrder = i
			label.Parent = self.QuestTasks
		end
	end
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
	
	-- Apply standardized hover/click effects
	self:ApplyButtonEffects(btn, UDim2.new(0, 80, 0, 80))
	
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
	
	-- Shop Button
	local shopBtn = self:CreateActionButton("🛒", UDim2.new(0, 0, 0, 0), Color3.fromRGB(200, 150, 50))
	shopBtn.Size = UDim2.new(0, 50, 0, 50)
	shopBtn.LayoutOrder = 2
	shopBtn.Parent = frame
	
	shopBtn.Activated:Connect(function()
		self:ToggleShop()
	end)
	
	-- Hub Button
	local hubBtn = self:CreateActionButton("🏠", UDim2.new(0, 0, 0, 0), Color3.fromRGB(50, 150, 100))
	hubBtn.Size = UDim2.new(0, 50, 0, 50)
	hubBtn.LayoutOrder = 3
	hubBtn.Parent = frame
	
	hubBtn.Activated:Connect(function()
		self.TeleportToHub:FireServer()
	end)
end

function UIController:CreateShopUI(parent)
	local frame = self:CreateGlassPanel(UDim2.new(0, 350, 0, 450), UDim2.new(0.5, -175, 0.5, -225))
	frame.Name = "ShopFrame"
	frame.Visible = false
	frame.Parent = parent
	self.ShopFrame = frame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "🛒 SHOP"
	title.TextColor3 = THEME.ACCENT_COLOR
	title.Font = THEME.FONT
	title.TextSize = 24
	title.Parent = frame
	
	-- Close Button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = THEME.FONT
	closeBtn.TextSize = 18
	closeBtn.Parent = frame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = closeBtn
	
	closeBtn.Activated:Connect(function()
		self:ToggleShop()
	end)
	
	-- Items List
	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -20, 1, -60)
	list.Position = UDim2.new(0, 10, 0, 50)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.CanvasSize = UDim2.new(0, 0, 0, #Constants.SHOP_ITEMS * 75)
	list.ScrollBarThickness = 6
	list.Parent = frame
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	
	-- Create items from Constants.SHOP_ITEMS
	for i, item in ipairs(Constants.SHOP_ITEMS) do
		self:CreateShopItem(list, item, i)
	end
end

function UIController:CreateShopItem(parent, itemData, order)
	local frame = Instance.new("Frame")
	frame.Name = itemData.id
	frame.Size = UDim2.new(1, -10, 0, 65)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.BackgroundTransparency = 0.5
	frame.LayoutOrder = order
	frame.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.55, 0, 0, 25)
	nameLabel.Position = UDim2.new(0, 10, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemData.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Font = THEME.FONT
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = frame
	
	-- Type label
	local typeLabel = Instance.new("TextLabel")
	typeLabel.Size = UDim2.new(0.55, 0, 0, 18)
	typeLabel.Position = UDim2.new(0, 10, 0, 28)
	typeLabel.BackgroundTransparency = 1
	typeLabel.Text = "[" .. itemData.type:upper() .. "]"
	typeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	typeLabel.Font = Enum.Font.Gotham
	typeLabel.TextSize = 12
	typeLabel.TextXAlignment = Enum.TextXAlignment.Left
	typeLabel.Parent = frame
	
	local costLabel = Instance.new("TextLabel")
	costLabel.Size = UDim2.new(0.55, 0, 0, 20)
	costLabel.Position = UDim2.new(0, 10, 0, 44)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = "🪙 " .. tostring(itemData.price) .. " Gold"
	costLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	costLabel.Font = Enum.Font.Gotham
	costLabel.TextSize = 14
	costLabel.TextXAlignment = Enum.TextXAlignment.Left
	costLabel.Parent = frame
	
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 80, 0, 40)
	buyBtn.Position = UDim2.new(1, -90, 0.5, -20)
	buyBtn.BackgroundColor3 = THEME.ACCENT_COLOR
	buyBtn.Text = "BUY"
	buyBtn.TextColor3 = Color3.new(1, 1, 1)
	buyBtn.Font = THEME.FONT
	buyBtn.TextSize = 14
	buyBtn.Parent = frame
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = buyBtn
	
	buyBtn.Activated:Connect(function()
		buyBtn.Text = "..."
		buyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		
		local success, msg = self.PurchaseItemFunc:InvokeServer(itemData.id)
		
		if success then
			buyBtn.Text = "✓"
			buyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
			self:DisplayAnnouncement("Purchased " .. itemData.name .. "!", Color3.fromRGB(0, 255, 100))
		else
			buyBtn.Text = "✗"
			buyBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			self:DisplayAnnouncement(msg or "Purchase Failed", Color3.fromRGB(255, 50, 50))
		end
		
		task.delay(1, function()
			buyBtn.Text = "BUY"
			buyBtn.BackgroundColor3 = THEME.ACCENT_COLOR
		end)
	end)
end

function UIController:ToggleShop()
	if not self.ShopFrame then return end
	
	if self.ShopFrame.Visible then
		self:TweenPanelOut(self.ShopFrame)
	else
		self:TweenPanelIn(self.ShopFrame, UDim2.new(0, 350, 0, 450))
	end
end

function UIController:CreateContextButtons(parent)
	local frame = Instance.new("Frame")
	frame.Name = "ContextButtons"
	frame.Size = UDim2.new(0, 60, 0, 200)
	frame.Position = UDim2.new(1, -80, 0.5, -100)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	self.ContextButtonsFrame = frame
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Parent = frame
	
	-- Boat Button
	local boatBtn = self:CreateActionButton("🚤", UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 150, 200))
	boatBtn.Size = UDim2.new(0, 50, 0, 50)
	boatBtn.LayoutOrder = 1
	boatBtn.Visible = false
	boatBtn.Parent = frame
	self.BoatButton = boatBtn
	
	boatBtn.Activated:Connect(function()
		self.SpawnVehicle:FireServer("Skiff")
	end)
end

function UIController:CreateBossBar(parent)
	local frame = Instance.new("Frame")
	frame.Name = "BossHealthBar"
	frame.Size = UDim2.new(0, 400, 0, 20)
	frame.Position = UDim2.new(0.5, -200, 0, 50)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = parent
	self.BossBarFrame = frame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = frame
	
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	fill.BorderSizePixel = 0
	fill.Parent = frame
	self.BossBarFill = fill
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill
	
	local label = Instance.new("TextLabel")
	label.Name = "BossName"
	label.Size = UDim2.new(1, 0, 0, 20)
	label.Position = UDim2.new(0, 0, -1, -5)
	label.BackgroundTransparency = 1
	label.Text = "BOSS NAME"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = THEME.FONT
	label.TextSize = 18
	label.TextStrokeTransparency = 0.5
	label.Parent = frame
	self.BossNameLabel = label
end

function UIController:CreateTitleCard(parent)
	local frame = Instance.new("Frame")
	frame.Name = "TitleCard"
	frame.Size = UDim2.new(1, 0, 0, 150)
	frame.Position = UDim2.new(0, 0, 0.3, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = parent
	self.TitleCardFrame = frame
	
	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.new(1, 0, 0.6, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = "BOSS NAME"
	label.TextColor3 = Color3.fromRGB(255, 50, 50)
	label.Font = Enum.Font.Creepster
	label.TextScaled = true
	label.TextStrokeTransparency = 0
	label.Parent = frame
	self.TitleCardLabel = label
	
	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Subtitle"
	subLabel.Size = UDim2.new(1, 0, 0.3, 0)
	subLabel.Position = UDim2.new(0, 0, 0.6, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = "HAS AWAKENED"
	subLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	subLabel.Font = Enum.Font.GothamBold
	subLabel.TextScaled = true
	subLabel.TextStrokeTransparency = 0.5
	subLabel.Parent = frame
end

function UIController:ShowTitleCard(bossName)
	if not self.TitleCardFrame then return end
	
	self.TitleCardLabel.Text = bossName or "UNKNOWN ENTITY"
	self.TitleCardFrame.Visible = true
	self.TitleCardFrame.BackgroundTransparency = 1
	
	-- Animation
	local originalPos = UDim2.new(0, 0, 0.3, 0)
	self.TitleCardFrame.Position = UDim2.new(-1, 0, 0.3, 0)
	
	self.TitleCardFrame:TweenPosition(
		originalPos,
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Back,
		1,
		true
	)
	
	task.delay(4, function()
		self.TitleCardFrame:TweenPosition(
			UDim2.new(1, 0, 0.3, 0),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			1,
			true,
			function()
				self.TitleCardFrame.Visible = false
				self.TitleCardFrame.Position = originalPos
			end
		)
	end)
end

function UIController:DisplayAnnouncement(message, color)
	local screenGui = self.ScreenGui
	if not screenGui then return end
	
	local label = Instance.new("TextLabel")
	label.Name = "Announcement"
	label.Size = UDim2.new(1, 0, 0, 80)
	label.Position = UDim2.new(0, 0, 0.15, 0)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.SciFi
	label.TextScaled = true
	label.TextStrokeTransparency = 0
	label.Parent = screenGui
	
	-- Animate
	label.TextTransparency = 1
	label.TextStrokeTransparency = 1
	
	local t1 = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 0, TextStrokeTransparency = 0})
	t1:Play()
	
	task.delay(5, function()
		local t2 = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1})
		t2:Play()
		t2.Completed:Connect(function()
			label:Destroy()
		end)
	end)
end

function UIController:ShowBossBar(data)
	if not self.BossBarFrame then return end
	
	self.BossNameLabel.Text = data.Name or "BOSS"
	self.BossBarFill.Size = UDim2.new(1, 0, 1, 0)
	self.BossBarFrame.Visible = true
end

function UIController:UpdateBossBar(current, max)
	if not self.BossBarFrame or not self.BossBarFill then return end
	
	local percent = math.clamp(current / max, 0, 1)
	self.BossBarFill:TweenSize(
		UDim2.new(percent, 0, 1, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.2,
		true
	)
end

function UIController:HideBossBar()
	if not self.BossBarFrame then return end
	self.BossBarFrame.Visible = false
end

function UIController:FormatNumber(n)
	return tostring(n)
end

-- Panel Animation Helpers
function UIController:TweenPanelIn(panel, targetSize)
	panel.Size = UDim2.new(0, 0, 0, 0)
	panel.BackgroundTransparency = 1
	panel.Visible = true
	
	local sizeTween = TweenService:Create(panel, TweenInfo.new(ANIM.PANEL_OPEN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = targetSize,
		BackgroundTransparency = THEME.GLASS_TRANSPARENCY
	})
	sizeTween:Play()
	return sizeTween
end

function UIController:TweenPanelOut(panel, callback)
	local closeTween = TweenService:Create(panel, TweenInfo.new(ANIM.PANEL_CLOSE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1
	})
	closeTween:Play()
	closeTween.Completed:Connect(function()
		panel.Visible = false
		if callback then callback() end
	end)
	return closeTween
end

-- Enhanced Button Effects
function UIController:ApplyButtonEffects(btn, originalSize)
	local origSizeX = originalSize and originalSize.X.Offset or btn.Size.X.Offset
	local origSizeY = originalSize and originalSize.Y.Offset or btn.Size.Y.Offset
	local hoverSize = UDim2.new(0, origSizeX * ANIM.HOVER_SCALE, 0, origSizeY * ANIM.HOVER_SCALE)
	local clickSize = UDim2.new(0, origSizeX * ANIM.CLICK_SCALE, 0, origSizeY * ANIM.CLICK_SCALE)
	local normalSize = UDim2.new(0, origSizeX, 0, origSizeY)
	local origColor = btn.BackgroundColor3
	local hoverColor = Color3.new(
		math.min(origColor.R * 1.2, 1),
		math.min(origColor.G * 1.2, 1),
		math.min(origColor.B * 1.2, 1)
	)
	
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(ANIM.BUTTON_HOVER_TIME, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
			Size = hoverSize,
			BackgroundColor3 = hoverColor
		}):Play()
	end)
	
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(ANIM.BUTTON_HOVER_TIME, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
			Size = normalSize,
			BackgroundColor3 = origColor
		}):Play()
	end)
	
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(ANIM.BUTTON_CLICK_TIME, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
			Size = clickSize
		}):Play()
	end)
	
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(ANIM.BUTTON_CLICK_TIME, ANIM.EASING_STYLE, ANIM.EASING_DIRECTION), {
			Size = hoverSize
		}):Play()
	end)
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
