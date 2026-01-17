--[[
	InventoryController.lua
	Manages the inventory UI and equipping spirits.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maid = require(Shared.Modules.Maid)
local Remotes = require(Shared.Remotes)

local InventoryController = {}
InventoryController._maid = nil

function InventoryController:Init()
	print("[InventoryController] Initializing...")
	
	self._maid = Maid.new()
	self.Player = Players.LocalPlayer
	self.PlayerGui = self.Player:WaitForChild("PlayerGui")
	
	self.IsVisible = false
	
	-- Wait for MainHUD to be created by UIController
	task.spawn(function()
		local mainUI = self.PlayerGui:WaitForChild("MainUI", 10)
		local hud = mainUI and mainUI:WaitForChild("MainHUD", 10)
		if hud then
			self:CreateInventoryUI(hud)
		else
			warn("[InventoryController] MainHUD not found")
		end
	end)
	
	local UpdateHUD = Remotes.GetEvent("UpdateHUD")
	self._maid:GiveTask(UpdateHUD.OnClientEvent:Connect(function(data)
		if data and data.Inventory then
			self:UpdateInventory(data.Inventory)
		end
	end))
end

function InventoryController:Start()
	print("[InventoryController] Starting...")
	
	-- Cleanup when player leaves
	self._maid:GiveTask(Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == self.Player then
			self:Destroy()
		end
	end))
end

function InventoryController:Toggle()
	if not self.MainFrame then return end
	self.IsVisible = not self.IsVisible
	self.MainFrame.Visible = self.IsVisible
end

function InventoryController:CreateInventoryUI(parent)
	local frame = Instance.new("Frame")
	frame.Name = "InventoryFrame"
	
	-- Glassmorphism Style
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	frame.BackgroundTransparency = 0.4
	frame.BorderSizePixel = 0
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.8
	stroke.Parent = frame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	frame.Size = UDim2.new(0, 400, 0, 300)
	frame.Position = UDim2.new(0.5, -200, 0.5, -150)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = parent
	
	-- Add corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	
	self.MainFrame = frame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Text = "SPIRITS"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.Parent = frame
	
	-- Close Button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Text = "X"
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = frame
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn
	
	closeBtn.Activated:Connect(function()
		self:Toggle()
	end)
	
	-- Grid
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -20, 1, -60)
	scroll.Position = UDim2.new(0, 10, 0, 50)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Parent = frame
	
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0, 90, 0, 110)
	layout.CellPadding = UDim2.new(0, 10, 0, 10)
	layout.Parent = scroll
	
	self.Container = scroll
end

function InventoryController:UpdateInventory(inventory)
	if not self.Container then return end
	
	-- Clear existing
	for _, child in ipairs(self.Container:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	if not inventory or not inventory.Spirits then return end
	
	local EquipSpirit = Remotes.GetEvent("EquipSpirit")
	
	for uniqueId, spirit in pairs(inventory.Spirits) do
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		btn.Text = ""
		btn.Parent = self.Container
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn
		
		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, 0, 0, 20)
		name.Position = UDim2.new(0, 0, 1, -25)
		name.BackgroundTransparency = 1
		name.Text = spirit.Name
		name.TextColor3 = Color3.new(1, 1, 1)
		name.TextSize = 14
		name.Font = Enum.Font.Gotham
		name.Parent = btn
		
		local level = Instance.new("TextLabel")
		level.Size = UDim2.new(1, 0, 0, 20)
		level.Position = UDim2.new(0, 0, 0, 5)
		level.BackgroundTransparency = 1
		level.Text = "Lvl " .. spirit.Level
		level.TextColor3 = Color3.fromRGB(200, 200, 255)
		level.TextSize = 12
		level.Font = Enum.Font.Gotham
		level.Parent = btn
		
		-- Equipped indicator
		if inventory.EquippedSpirit == uniqueId then
			local border = Instance.new("UIStroke")
			border.Color = Color3.fromRGB(0, 255, 100)
			border.Thickness = 3
			border.Parent = btn
			
			local equippedLbl = Instance.new("TextLabel")
			equippedLbl.Text = "EQUIPPED"
			equippedLbl.Size = UDim2.new(1, 0, 0, 20)
			equippedLbl.Position = UDim2.new(0, 0, 0.5, -10)
			equippedLbl.BackgroundTransparency = 1
			equippedLbl.TextColor3 = Color3.fromRGB(0, 255, 100)
			equippedLbl.Font = Enum.Font.GothamBlack
			equippedLbl.TextSize = 12
			equippedLbl.Parent = btn
		end
		
		btn.Activated:Connect(function()
			EquipSpirit:FireServer(uniqueId)
		end)
	end
end

function InventoryController:Destroy()
	if self._maid then
		self._maid:Destroy()
	end
end

return InventoryController
