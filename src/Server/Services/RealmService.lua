--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ContentProvider = game:GetService("ContentProvider")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- Assuming DataService is a sibling
local DataService = require(script.Parent.DataService)

local RealmService = {}
RealmService.RealmInstances = {} -- [playerId] = Model
RealmService.RealmAccess = {} -- [ownerId] = AccessLevel
RealmService.RealmOccupants = {} -- [ownerId] = count
RealmService.PlayerCurrentRealm = {} -- [playerId] = ownerId

-- Constants (Placeholder)
local BUILDABLE_ITEMS = {
	["chair_01"] = { Name = "Wooden Chair", Cost = 10, ModelId = "rbxassetid://0" },
	["table_01"] = { Name = "Wooden Table", Cost = 20, ModelId = "rbxassetid://0" },
	["lamp_01"] = { Name = "Street Lamp", Cost = 50, ModelId = "rbxassetid://0" },
	["fountain_01"] = { Name = "Small Fountain", Cost = 100, ModelId = "rbxassetid://0" },
}

function RealmService:Init()
	print("[RealmService] Initializing...")
	
	-- Ensure PlayerRealms folder exists
	if not workspace:FindFirstChild("PlayerRealms") then
		local folder = Instance.new("Folder")
		folder.Name = "PlayerRealms"
		folder.Parent = workspace
	end
end

function RealmService:Start()
	print("[RealmService] Starting...")
	
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerRemoving(player)
	end)
	
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:OnPlayerAdded(player)
		end)
	end
	
	-- Listen for TeleportToHub (Teleport to Home Realm)
	local TeleportToHub = Remotes.GetEvent("TeleportToHub")
	TeleportToHub.OnServerEvent:Connect(function(player)
		self:TeleportToRealm(player, player.UserId)
	end)
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
	
	-- Default Access Level
	self.RealmAccess[player.UserId] = Constants.REALM_ACCESS.FRIENDS
	self.RealmOccupants[player.UserId] = 0
	
	self:CreateRealmInstance(player)
	
	-- Teleport when character spawns
	player.CharacterAdded:Connect(function(character)
		-- Wait a brief moment for physics to initialize
		task.wait(1) -- Increased wait time for stability
		self:TeleportToRealm(player, player.UserId)
	end)
	
	-- Teleport if character already exists
	if player.Character then
		task.spawn(function()
			task.wait(1) -- Increased wait time for stability
			self:TeleportToRealm(player, player.UserId)
		end)
	end
end

function RealmService:OnPlayerRemoving(player: Player)
	-- Remove from current realm tracking
	local currentRealmOwner = self.PlayerCurrentRealm[player.UserId]
	if currentRealmOwner and self.RealmOccupants[currentRealmOwner] then
		self.RealmOccupants[currentRealmOwner] = math.max(0, self.RealmOccupants[currentRealmOwner] - 1)
	end
	self.PlayerCurrentRealm[player.UserId] = nil
	
	-- Clean up own realm tracking
	self.RealmAccess[player.UserId] = nil
	self.RealmOccupants[player.UserId] = nil
	
	-- Cleanup instance if needed (optional, keeping for persistence in session)
end

function RealmService:SetAccessLevel(player: Player, level: string)
	if level == Constants.REALM_ACCESS.PRIVATE or 
	   level == Constants.REALM_ACCESS.FRIENDS or 
	   level == Constants.REALM_ACCESS.PUBLIC then
		self.RealmAccess[player.UserId] = level
		print("[RealmService] Set access level for " .. player.Name .. " to " .. level)
	end
end

function RealmService:JoinRealm(player: Player, targetPlayerId: number)
	local access = self.RealmAccess[targetPlayerId] or Constants.REALM_ACCESS.FRIENDS
	local canJoin = false
	
	if player.UserId == targetPlayerId then
		canJoin = true
	elseif access == Constants.REALM_ACCESS.PUBLIC then
		canJoin = true
	elseif access == Constants.REALM_ACCESS.FRIENDS then
		if player:IsFriendsWith(targetPlayerId) then
			canJoin = true
		end
	elseif access == Constants.REALM_ACCESS.PRIVATE then
		canJoin = false
	end
	
	if canJoin then
		self:TeleportToRealm(player, targetPlayerId)
	else
		warn("[RealmService] Access Denied to realm of " .. targetPlayerId)
	end
end

function RealmService:GetXPMultiplier(player: Player)
	local currentRealmOwner = self.PlayerCurrentRealm[player.UserId]
	if currentRealmOwner then
		local count = self.RealmOccupants[currentRealmOwner] or 0
		if count >= 3 then
			return 1.1 -- 10% bonus
		end
	end
	return 1.0
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
	base.Size = Constants.REALM_ISLAND_SIZE
	base.Material = Enum.Material.Grass
	base.Color = Color3.fromRGB(75, 151, 75) -- Green
	base.Anchored = true
	
	-- 2D Grid Layout
	local gridWidth = Constants.REALM_GRID_WIDTH
	local spacing = Constants.REALM_GRID_SPACING
	
	local idx = player.UserId % 10000
	local gridX = idx % gridWidth
	local gridZ = math.floor(idx / gridWidth)
	
	base.Position = Vector3.new(gridX * spacing, 500, gridZ * spacing)
	base.Parent = realmModel
	realmModel.PrimaryPart = base
	
	-- Create House
	self:CreateHouse(realmModel, base.Position)
	
	-- Create Spire
	self:CreateSpire(realmModel, base.Position + Vector3.new(-40, 0, 40) + Vector3.new(0, 5, 0))
	
	-- Create Trees
	for i = 1, 5 do
		local tree = Instance.new("Model")
		tree.Name = "Tree"
		
		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Size = Vector3.new(2, 8, 2)
		trunk.Color = Color3.fromRGB(101, 67, 33)
		trunk.Anchored = true
		trunk.Parent = tree
		
		local leaves = Instance.new("Part")
		leaves.Name = "Leaves"
		leaves.Size = Vector3.new(6, 6, 6)
		leaves.Color = Color3.fromRGB(34, 139, 34)
		leaves.Anchored = true
		leaves.Shape = Enum.PartType.Ball
		leaves.Parent = tree
		
		-- Random position on base, avoiding house center
		local angle = math.random() * math.pi * 2
		local radius = math.random(15, 40)
		local tx = base.Position.X + math.cos(angle) * radius
		local tz = base.Position.Z + math.sin(angle) * radius
		
		trunk.Position = Vector3.new(tx, base.Position.Y + 4, tz)
		leaves.Position = trunk.Position + Vector3.new(0, 6, 0)
		
		tree.Parent = realmModel
	end
	
	-- Create Portal to Combat Zone
	local portal = Instance.new("Part")
	portal.Name = "CombatPortal"
	portal.Size = Vector3.new(6, 8, 1)
	portal.Position = base.Position + Vector3.new(30, 5, 0)
	portal.Color = Color3.fromRGB(100, 0, 255)
	portal.Material = Enum.Material.Neon
	portal.Anchored = true
	portal.Parent = realmModel
	
	local portalPrompt = Instance.new("ProximityPrompt")
	portalPrompt.ObjectText = "Combat Zone"
	portalPrompt.ActionText = "Travel"
	portalPrompt.Parent = portal
	
	portalPrompt.Triggered:Connect(function(triggerPlayer)
		if triggerPlayer == player then
			self:TeleportToCombatZone(player)
		end
	end)
	
	-- Create NPC (Guide)
	local npc = Instance.new("Part")
	npc.Name = "GuideNPC"
	npc.Size = Vector3.new(2, 5, 2)
	npc.Position = base.Position + Vector3.new(10, 3.5, 10)
	npc.Color = Color3.fromRGB(255, 255, 0)
	npc.Material = Enum.Material.Neon
	npc.Anchored = true
	npc.CanCollide = true -- Changed to true so players don't walk through
	npc.Parent = realmModel
	
	local npcPrompt = Instance.new("ProximityPrompt")
	npcPrompt.ObjectText = "Guide"
	npcPrompt.ActionText = "Talk"
	npcPrompt.Parent = npc
	
	-- Load items
	if data.Realm and data.Realm.Items then
		for _, itemData in ipairs(data.Realm.Items) do
			-- Visuals would be created here
		end
	end
	
	realmModel.Parent = workspace.PlayerRealms
	self.RealmInstances[player.UserId] = realmModel
	
	return realmModel
end

function RealmService:CreateHouse(parent: Model, centerPos: Vector3)
	local house = Instance.new("Model")
	house.Name = "House"
	house.Parent = parent
	
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(20, 1, 20)
	floor.Position = centerPos + Vector3.new(0, 1, 0)
	floor.Color = Color3.fromRGB(139, 69, 19)
	floor.Anchored = true
	floor.Parent = house
	
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(22, 5, 22)
	roof.Position = centerPos + Vector3.new(0, 10, 0)
	roof.Color = Color3.fromRGB(160, 82, 45)
	roof.Anchored = true
	roof.Shape = Enum.PartType.Block
	roof.Parent = house
	
	-- Walls
	local wallSpecs = {
		{Size = Vector3.new(20, 8, 1), Offset = Vector3.new(0, 4.5, 9.5)},
		{Size = Vector3.new(20, 8, 1), Offset = Vector3.new(0, 4.5, -9.5)},
		{Size = Vector3.new(1, 8, 18), Offset = Vector3.new(9.5, 4.5, 0)}, -- Doorway side
		{Size = Vector3.new(1, 8, 20), Offset = Vector3.new(-9.5, 4.5, 0)},
	}
	
	for i, spec in ipairs(wallSpecs) do
		local wall = Instance.new("Part")
		wall.Name = "Wall" .. i
		wall.Size = spec.Size
		wall.Position = floor.Position + spec.Offset
		wall.Color = Color3.fromRGB(200, 180, 140)
		wall.Anchored = true
		wall.Parent = house
	end
end

function RealmService:CreateSpire(parent: Model, position: Vector3)
	local spireModel = Instance.new("Model")
	spireModel.Name = "Spire"
	
	local base = Instance.new("Part")
	base.Name = "SpireBase"
	base.Size = Vector3.new(12, 30, 12)
	base.Position = position + Vector3.new(0, 15, 0)
	base.Color = Color3.fromRGB(40, 40, 50)
	base.Material = Enum.Material.Slate
	base.Anchored = true
	base.Parent = spireModel
	
	local crystal = Instance.new("Part")
	crystal.Name = "SpireCrystal"
	crystal.Size = Vector3.new(6, 12, 6)
	crystal.Position = base.Position + Vector3.new(0, 20, 0)
	crystal.Color = Color3.fromRGB(0, 255, 255)
	crystal.Material = Enum.Material.Neon
	crystal.Anchored = true
	crystal.Parent = spireModel
	
	-- Floating rings
	for i = 1, 3 do
		local ring = Instance.new("Part")
		ring.Name = "Ring" .. i
		ring.Size = Vector3.new(18 + (i*2), 1, 18 + (i*2))
		ring.Position = crystal.Position
		ring.Orientation = Vector3.new(math.random(0, 360), math.random(0, 360), math.random(0, 360))
		ring.Color = Color3.fromRGB(100, 200, 255)
		ring.Material = Enum.Material.Neon
		ring.Transparency = 0.4
		ring.Anchored = true
		ring.CanCollide = false
		ring.Parent = spireModel
	end
	
	spireModel.Parent = parent
end

function RealmService:TeleportToCombatZone(player: Player)
	if player.Character and player.Character.PrimaryPart then
		-- Teleport to Combat Zone (0, 5, 0)
		local targetPos = Vector3.new(0, 10, 0) + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
		player.Character:PivotTo(CFrame.new(targetPos))
		print("[RealmService] Teleported " .. player.Name .. " to Combat Zone")
	end
end

function RealmService:TeleportToRealm(visitor: Player, ownerId: number)
	local realmModel = self.RealmInstances[ownerId]
	if not realmModel then
		warn("[RealmService] Realm not found for ownerId: " .. ownerId)
		-- Try to create it if it's the owner
		if visitor.UserId == ownerId then
			realmModel = self:CreateRealmInstance(visitor)
		end
		
		if not realmModel then
			return
		end
	end
	
	-- Update Occupancy
	local previousRealmOwner = self.PlayerCurrentRealm[visitor.UserId]
	if previousRealmOwner and previousRealmOwner ~= ownerId then
		if self.RealmOccupants[previousRealmOwner] then
			self.RealmOccupants[previousRealmOwner] = math.max(0, self.RealmOccupants[previousRealmOwner] - 1)
		end
	end
	
	if previousRealmOwner ~= ownerId then
		self.PlayerCurrentRealm[visitor.UserId] = ownerId
		self.RealmOccupants[ownerId] = (self.RealmOccupants[ownerId] or 0) + 1
	end
	
	if visitor.Character and visitor.Character.PrimaryPart then
		-- Teleport to center + 50 studs up (Streaming Safety Buffer)
		local targetCFrame = realmModel.PrimaryPart.CFrame + Vector3.new(0, 50, 0)
		
		-- Streaming Safety: Request area to load before teleporting
		visitor:RequestStreamAroundAsync(targetCFrame.Position)
		
		-- Hard Anchor Sequence
		local rootPart = visitor.Character.PrimaryPart
		if rootPart then
			rootPart.Anchored = true
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
			
			visitor.Character:PivotTo(targetCFrame)
			
			-- Force character appearance update
			if visitor.Character:FindFirstChild("Humanoid") then
				visitor.Character.Humanoid:BuildRigFromAttachments()
			end
			
			task.delay(3, function() -- Wait 3 seconds as requested
				if rootPart and rootPart.Parent then
					rootPart.Anchored = false
				end
			end)
		end
		
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
