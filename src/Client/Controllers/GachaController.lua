local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Modules.Constants)
local Maid = require(Shared.Modules.Maid)

local GachaController = {}
GachaController._maid = nil

function GachaController:Init()
	print("[GachaController] Initializing...")
	self._maid = Maid.new()
end

function GachaController:Start()
	print("[GachaController] Starting...")
	
	local player = Players.LocalPlayer
	
	-- Cleanup when player leaves
	self._maid:GiveTask(Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == player then
			self:Destroy()
		end
	end))
	
	self:CreateUI()
end

function GachaController:CreateUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GachaUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	self._maid:GiveTask(screenGui)
	
	-- Summon Button (Top Right)
	local summonBtn = Instance.new("TextButton")
	summonBtn.Name = "SummonButton"
	summonBtn.Size = UDim2.new(0, 150, 0, 50)
	summonBtn.Position = UDim2.new(1, -170, 0, 20)
	summonBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
	summonBtn.Text = "Summon Spirit\n(" .. Constants.GACHA.COST.Amount .. " " .. Constants.GACHA.COST.Currency .. ")"
	summonBtn.TextColor3 = Color3.new(1, 1, 1)
	summonBtn.Font = Enum.Font.GothamBold
	summonBtn.TextSize = 14
	summonBtn.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = summonBtn
	
	self._maid:GiveTask(summonBtn.Activated:Connect(function()
		self:PerformSummon(1)
	end))
end

function GachaController:PerformSummon(amount)
	print("Summoning...")
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes then return end
	
	local gachaFolder = remotes:WaitForChild("Gacha", 10)
	if not gachaFolder then return end
	
	local summonFunc = gachaFolder:WaitForChild("Summon", 10)
	if not summonFunc then return end
	
	local result = summonFunc:InvokeServer(amount)
	
	if result.Success then
		print("Summon Success!")
		for _, spirit in ipairs(result.Results) do
			print("Got: " .. spirit.Name .. " (" .. spirit.Rarity .. ")")
			self:ShowResult(spirit)
		end
	else
		warn("Summon Failed: " .. tostring(result.Message))
		self:ShowError(result.Message)
	end
end

function GachaController:ShowResult(spirit)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local screenGui = playerGui:FindFirstChild("GachaUI")
	if not screenGui then return end
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 400, 0, 80)
	label.Position = UDim2.new(0.5, -200, 0.4, 0)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	label.BackgroundTransparency = 0.1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "SUMMONED!\n" .. spirit.Name .. "\n" .. spirit.Rarity
	label.Font = Enum.Font.GothamBold
	label.TextSize = 24
	label.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = self:GetRarityColor(spirit.Rarity)
	stroke.Thickness = 3
	stroke.Parent = label
	
	-- Animate
	label.Position = UDim2.new(0.5, -200, 0.5, 0)
	local tweenService = game:GetService("TweenService")
	local tween = tweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, -200, 0.4, 0)})
	tween:Play()
	
	Debris:AddItem(label, 3)
end

function GachaController:ShowError(msg)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local screenGui = playerGui:FindFirstChild("GachaUI")
	if not screenGui then return end
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 300, 0, 40)
	label.Position = UDim2.new(0.5, -150, 0.8, 0)
	label.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "Error: " .. msg
	label.Font = Enum.Font.Gotham
	label.TextSize = 18
	label.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	
	Debris:AddItem(label, 2)
end

function GachaController:GetRarityColor(rarity)
	if rarity == "Legendary" then return Color3.fromRGB(255, 170, 0) end
	if rarity == "Epic" then return Color3.fromRGB(170, 0, 255) end
	if rarity == "Rare" then return Color3.fromRGB(0, 170, 255) end
	if rarity == "Uncommon" then return Color3.fromRGB(0, 255, 0) end
	return Color3.fromRGB(200, 200, 200)
end

function GachaController:Destroy()
	if self._maid then
		self._maid:Destroy()
	end
end

return GachaController
