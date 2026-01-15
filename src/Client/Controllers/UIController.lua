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
	
	-- Currency Frame (Top Right)
	local currencyFrame = Instance.new("Frame")
	currencyFrame.Name = "CurrencyFrame"
	currencyFrame.Size = UDim2.new(0, 200, 0, 100)
	currencyFrame.Position = UDim2.new(1, -210, 0, 10)
	currencyFrame.BackgroundTransparency = 0.5
	currencyFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	currencyFrame.BorderSizePixel = 0
	currencyFrame.Parent = mainHUD
	
	local layout = Instance.new("UIListLayout")
	layout.Parent = currencyFrame
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	
	local padding = Instance.new("UIPadding")
	padding.Parent = currencyFrame
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingLeft = UDim.new(0, 5)
	padding.PaddingRight = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)
	
	-- Helper to create labels
	local function createLabel(name, color, order)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.new(1, 0, 0, 25)
		label.BackgroundTransparency = 1
		label.TextColor3 = color
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.Text = name .. ": 0"
		label.LayoutOrder = order
		label.Parent = currencyFrame
		
		currencyLabels[name] = label
	end
	
	createLabel("Essence", Color3.fromRGB(100, 255, 100), 1) -- Green
	createLabel("Aether", Color3.fromRGB(100, 200, 255), 2)  -- Blue
	createLabel("Crystals", Color3.fromRGB(255, 100, 255), 3) -- Purple
end

function UIController:UpdateHUD(data)
	if not data then return end
	
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
end

return UIController
