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
	GLASS_TRANSPARENCY = 0.25,
	ACCENT_COLOR = Color3.fromRGB(0, 170, 255),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	FONT = Enum.Font.GothamBold,
	CORNER_RADIUS = UDim.new(0, 12)
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
	local currencyFrame = self:CreateGlassPanel(UDim2.new(0, 220, 0, 90), UDim2.new(0, 20, 0, 20))
	currencyFrame.Name = "CurrencyPanel"
	currencyFrame.Parent = screenGui
	
	self.EssenceLabel = self:CreateCurrencyLabel("Essence", "✨", 0, currencyFrame)
	self.AetherLabel = self:CreateCurrencyLabel("Aether", "💎", 1, currencyFrame)
	self.CrystalsLabel = self:CreateCurrencyLabel("Crystals", "🔮", 2, currencyFrame)
	
	-- 1.5 Menu Buttons (Left Side)
	self:CreateMenuButtons(screenGui)
	
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
	
	if self.ZoneLabel and self.ZoneLabel.Text ~= currentZone then
		self.ZoneLabel.Text = currentZone
		
		-- Pulse effect
		local t = TweenService:Create(self.ZoneLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {TextSize = 22})
		t:Play()
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
	
	-- Hover Effects
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(0, 88, 0, 88)}):Play()
	end)
	
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(0, 80, 0, 80)}):Play()
	end)
	
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
