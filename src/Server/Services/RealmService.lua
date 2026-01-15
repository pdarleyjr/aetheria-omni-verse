--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Assuming DataService is a sibling
local DataService = require(script.Parent.DataService)

local RealmService = {}
RealmService.RealmInstances = {} -- [playerId] = Model

-- Constants (Placeholder)
local BUILDABLE_ITEMS = {
	["chair_01"] = { Name = "Wooden Chair", Cost = 10 },
	["table_01"] = { Name = "Wooden Table", Cost = 20 },
}

function RealmService:Init()
	print("[RealmService] Initializing...")
end

function RealmService:Start()
	print("[RealmService] Starting...")
	
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)
	
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:OnPlayerAdded(player)
		end)
	end
end

function RealmService:OnPlayerAdded(player: Player)
	-- Wait for data to be loaded
	local data = nil
	for i = 1, 10 do
		data = DataService.GetData(player)
		if data then break end
		task.wait(1)
	end
	
	if not data then
		warn("[RealmService] Could not load data for " .. player.Name)
		return
	end
	
	-- Initialize Realm data if missing
	if not data.Realm then
		data.Realm = {
			Items = {},
			LastIncomeCollection = os.time()
		}
	end
	
	self:CreateRealmInstance(player)
end

function RealmService:CreateRealmInstance(player: Player)
	local data = DataService.GetData(player)
	if not data then return end
	
	if self.RealmInstances[player.UserId] then
		return self.RealmInstances[player.UserId]
	end

	print("[RealmService] Creating Realm for " .. player.Name)
	
	local realmModel = Instance.new("Model")
	realmModel.Name = player.Name .. "_Realm"
	
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(100, 1, 100)
	base.Anchored = true
	base.Position = Vector3.new(0, 1000 + (player.UserId % 100) * 200, 0)
	base.Parent = realmModel
	realmModel.PrimaryPart = base
	
	-- Load items
	if data.Realm and data.Realm.Items then
		for _, itemData in ipairs(data.Realm.Items) do
			print("[RealmService] Loading item: " .. itemData.ItemId)
			-- Visuals would be created here
		end
	end
	
	realmModel.Parent = workspace
	self.RealmInstances[player.UserId] = realmModel
	
	return realmModel
end

function RealmService:TeleportToRealm(visitor: Player, ownerId: number)
	local realmModel = self.RealmInstances[ownerId]
	if not realmModel then
		warn("[RealmService] Realm not found for ownerId: " .. ownerId)
		return
	end
	
	if visitor.Character and visitor.Character.PrimaryPart then
		local targetCFrame = realmModel.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
		visitor.Character:SetPrimaryPartCFrame(targetCFrame)
		print("[RealmService] Teleported " .. visitor.Name .. " to realm of " .. ownerId)
	end
end

function RealmService:PlaceFurniture(player: Player, itemId: string, cframe: CFrame)
	local data = DataService.GetData(player)
	if not data then return false end
	
	if not BUILDABLE_ITEMS[itemId] then
		warn("[RealmService] Invalid item ID: " .. itemId)
		return false
	end
	
	-- In a real game, we'd check currency here
	
	table.insert(data.Realm.Items, {
		ItemId = itemId,
		CFrame = cframe 
	})
	
	print("[RealmService] " .. player.Name .. " placed " .. itemId)
	return true
end

function RealmService:CalculatePassiveIncome(player: Player)
	local data = DataService.GetData(player)
	if not data or not data.Realm then return 0 end
	
	local itemCount = #data.Realm.Items
	local timeDiff = os.time() - data.Realm.LastIncomeCollection
	-- 1 coin per item per hour (3600 seconds)
	local income = math.floor(itemCount * (timeDiff / 3600))
	
	return income
end

return RealmService
