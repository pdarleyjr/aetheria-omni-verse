--[[
	UIController.lua
	Manages the main HUD and UI updates.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local UIController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mainHUD = nil
local currencyLabels = {}
local spiritLabels = {}

function UIController:Init()
	print("[UIController] Initializing...")
	self:CreateHUD()
end

function UIController:Start()
	print("[UIController] Starting...")
	
	local updateHUDEvent = Remotes.GetEvent("UpdateHUD")
	updateHUDEvent.OnClientEvent:Connect(function(data)
		self:UpdateHUD(data)
	end)
	
	-- Request initial update
	-- (Optional: Server could send it on load, but requesting ensures we are ready)
end

function UIController:CreateHUD()
	if mainHUD then return end
	
	mainHUD = Instance.new("ScreenGui")
	mainHUD.Name = "MainHUD"
	mainHUD.ResetOnSpawn = false
	mainHUD.Parent = playerGui
	
	-- // CURRENCY FRAME (Glassmorphism) //
	local currencyFrame = Instance.new("Frame")
	currencyFrame.Name = "CurrencyFrame"
	currencyFrame.Size = UDim2.new(0, 200, 0, 100)
	currencyFrame.Position = UDim2.new(1, -220, 0, 20)
	currencyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	currencyFrame.BackgroundTransparency = 0.3
	currencyFrame.BorderSizePixel = 0
	currencyFrame.Parent = mainHUD
	
	local curCorner = Instance.new("UICorner")
	curCorner.CornerRadius = UDim.new(0, 12)
	curCorner.Parent = currencyFrame
	
	local curStroke = Instance.new("UIStroke")
	curStroke.Color = Color3.fromRGB(255, 255, 255)
	curStroke.Transparency = 0.8
	curStroke.Thickness = 1
	curStroke.Parent = currencyFrame
	
	local layout = Instance.new("UIListLayout")
	layout.Parent = currencyFrame
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	
	local padding = Instance.new("UIPadding")
	padding.Parent = currencyFrame
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	
	-- Helper to create labels
	local function createLabel(name, color, order, parent, tableToStore)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.new(1, 0, 0, 20)
		label.BackgroundTransparency = 1
		label.TextColor3 = color
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.Text = name .. ": 0"
		label.LayoutOrder = order
		label.Parent = parent
		
		tableToStore[name] = label
	end
	
	createLabel("Essence", Color3.fromRGB(100, 255, 100), 1, currencyFrame, currencyLabels) -- Green
	createLabel("Aether", Color3.fromRGB(100, 200, 255), 2, currencyFrame, currencyLabels)  -- Blue
	createLabel("Crystals", Color3.fromRGB(255, 100, 255), 3, currencyFrame, currencyLabels) -- Purple
	
	-- // SPIRIT PANEL (Glassmorphism) //
	local spiritPanel = Instance.new("Frame")
	spiritPanel.Name = "SpiritPanel"
	spiritPanel.Size = UDim2.new(0, 220, 0, 120)
	spiritPanel.Position = UDim2.new(0, 20, 1, -140)
	spiritPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	spiritPanel.BackgroundTransparency = 0.3
	spiritPanel.BorderSizePixel = 0
	spiritPanel.Parent = mainHUD
	
	local spCorner = Instance.new("UICorner")
	spCorner.CornerRadius = UDim.new(0, 12)
	spCorner.Parent = spiritPanel
	
	local spStroke = Instance.new("UIStroke")
	spStroke.Color = Color3.fromRGB(255, 255, 255)
	spStroke.Transparency = 0.8
	spStroke.Thickness = 1
	spStroke.Parent = spiritPanel
	
	local spLayout = Instance.new("UIListLayout")
	spLayout.Parent = spiritPanel
	spLayout.SortOrder = Enum.SortOrder.LayoutOrder
	spLayout.Padding = UDim.new(0, 5)
	
	local spPadding = Instance.new("UIPadding")
	spPadding.Parent = spiritPanel
	spPadding.PaddingTop = UDim.new(0, 10)
	spPadding.PaddingLeft = UDim.new(0, 10)
	spPadding.PaddingRight = UDim.new(0, 10)
	spPadding.PaddingBottom = UDim.new(0, 10)
	
	-- Spirit Labels
	createLabel("SpiritName", Color3.fromRGB(255, 255, 200), 1, spiritPanel, spiritLabels)
	createLabel("Level", Color3.fromRGB(255, 255, 255), 2, spiritPanel, spiritLabels)
	createLabel("Exp", Color3.fromRGB(200, 200, 200), 3, spiritPanel, spiritLabels)
	
	spiritLabels["SpiritName"].Text = "No Spirit Equipped"
	spiritLabels["Level"].Text = "Level: -"
	spiritLabels["Exp"].Text = "EXP: -"
end

function UIController:UpdateHUD(data)
	if not data then return end
	
	-- Update Currencies
	if data.Currencies then
		if currencyLabels["Essence"] then
			currencyLabels["Essence"].Text = "Essence: " .. tostring(data.Currencies.Essence or 0)
		end
		if currencyLabels["Aether"] then
			currencyLabels["Aether"].Text = "Aether: " .. tostring(data.Currencies.Aether or 0)
		end
		if currencyLabels["Crystals"] then
			currencyLabels["Crystals"].Text = "Crystals: " .. tostring(data.Currencies.Crystals or 0)
		end
	end
	
	-- Update Spirit Panel
	if data.Inventory and data.Inventory.Equipped and data.Inventory.Spirits then
		local equippedId = data.Inventory.Equipped["Main"]
		if equippedId and data.Inventory.Spirits[equippedId] then
			local spirit = data.Inventory.Spirits[equippedId]
			
			if spiritLabels["SpiritName"] then
				spiritLabels["SpiritName"].Text = spirit.Name or "Unknown Spirit"
			end
			if spiritLabels["Level"] then
				spiritLabels["Level"].Text = "Level: " .. tostring(spirit.Level or 1)
			end
			if spiritLabels["Exp"] then
				spiritLabels["Exp"].Text = "EXP: " .. tostring(spirit.Exp or 0)
			end
		else
			if spiritLabels["SpiritName"] then spiritLabels["SpiritName"].Text = "No Spirit Equipped" end
			if spiritLabels["Level"] then spiritLabels["Level"].Text = "Level: -" end
			if spiritLabels["Exp"] then spiritLabels["Exp"].Text = "EXP: -" end
		end
	end
end

return UIController
