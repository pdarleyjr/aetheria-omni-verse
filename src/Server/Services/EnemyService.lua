--[[!strict]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Maid = require(ReplicatedStorage.Shared.Modules.Maid)
local SpiritService = require(script.Parent.SpiritService)
local QuestService = require(script.Parent.QuestService)

local EnemyService = {}
local maid = Maid.new()
local ENEMY_FOLDER_NAME = "Enemies"

-- State Machine States
local STATE_IDLE = "Idle"
local STATE_PATROL = "Patrol"
local STATE_AGGRO = "Aggro"
local STATE_ATTACK = "Attack"
local STATE_RETREAT = "Retreat"

-- Configuration - Updated per task specifications
local HUB_POSITION = Vector3.new(0, 0, 0)
local AGGRO_RANGE = 40 -- studs
local RETREAT_HEALTH_THRESHOLD = 0.25 -- 25%
local ELITE_SPAWN_CHANCE = 0.10
local MINI_BOSS_INTERVAL = 500 -- Every 500 studs from hub

-- Spatial partitioning grid
local GRID_SIZE = 100
local spatialGrid = {}
local enemyData = {} -- Stores per-enemy runtime data (threat tables, etc.)

-- Performance: Update frequency based on player distance
local UPDATE_FREQUENCIES = {
	{MaxDistance = 50, Interval = 0},       -- Every frame
	{MaxDistance = 150, Interval = 0.1},    -- 10 times/sec
	{MaxDistance = 300, Interval = 0.3},    -- 3 times/sec
	{MaxDistance = math.huge, Interval = 1}, -- 1 time/sec
}

--===============================
-- SPATIAL PARTITIONING
--===============================

local function getGridKey(position: Vector3): string
	local gx = math.floor(position.X / GRID_SIZE)
	local gz = math.floor(position.Z / GRID_SIZE)
	return gx .. "," .. gz
end

local function addToGrid(enemy: Model)
	local root = enemy:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local key = getGridKey(root.Position)
	if not spatialGrid[key] then
		spatialGrid[key] = {}
	end
	spatialGrid[key][enemy] = true
	enemy:SetAttribute("GridKey", key)
end

local function removeFromGrid(enemy: Model)
	local key = enemy:GetAttribute("GridKey")
	if key and spatialGrid[key] then
		spatialGrid[key][enemy] = nil
	end
end

local function updateGridPosition(enemy: Model)
	local root = enemy:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local oldKey = enemy:GetAttribute("GridKey")
	local newKey = getGridKey(root.Position)
	
	if oldKey ~= newKey then
		if oldKey and spatialGrid[oldKey] then
			spatialGrid[oldKey][enemy] = nil
		end
		if not spatialGrid[newKey] then
			spatialGrid[newKey] = {}
		end
		spatialGrid[newKey][enemy] = true
		enemy:SetAttribute("GridKey", newKey)
	end
end

--===============================
-- DIFFICULTY SCALING (Updated formulas per task)
--===============================

function EnemyService:GetDistanceFromHub(position: Vector3): number
	return (Vector3.new(position.X, 0, position.Z) - Vector3.new(HUB_POSITION.X, 0, HUB_POSITION.Z)).Magnitude
end

function EnemyService:GetDifficultyMultipliers(position: Vector3): (number, number, number)
	local distance = self:GetDistanceFromHub(position)
	
	-- Health: 1.0 + distance/500
	local healthMult = 1.0 + distance / 500
	-- Damage: 1.0 + distance/750
	local damageMult = 1.0 + distance / 750
	-- Speed: 1.0 + distance/1000, capped at 1.5x
	local speedMult = math.min(1.5, 1.0 + distance / 1000)
	
	return healthMult, damageMult, speedMult
end

function EnemyService:GetSpawnDensity(position: Vector3): number
	local distance = self:GetDistanceFromHub(position)
	-- base + floor(distance/200)
	return 1 + math.floor(distance / 200)
end

function EnemyService:ShouldSpawnMiniBoss(position: Vector3): boolean
	local distance = self:GetDistanceFromHub(position)
	-- Every 500 studs from Hub
	local nearestThreshold = math.floor(distance / MINI_BOSS_INTERVAL) * MINI_BOSS_INTERVAL
	if nearestThreshold > 0 and math.abs(distance - nearestThreshold) < 50 then
		return math.random() < 0.05 -- 5% chance at thresholds
	end
	return false
end

--===============================
-- THREAT TABLE MANAGEMENT
--===============================

local function initEnemyData(enemy: Model)
	enemyData[enemy] = {
		ThreatTable = {},
		LastUpdate = 0,
		Maid = Maid.new(),
	}
end

local function cleanupEnemyData(enemy: Model)
	if enemyData[enemy] then
		enemyData[enemy].Maid:DoCleaning()
		enemyData[enemy] = nil
	end
end

function EnemyService:AddThreat(enemy: Model, player: Player, amount: number)
	local data = enemyData[enemy]
	if not data then return end
	
	data.ThreatTable[player] = (data.ThreatTable[player] or 0) + amount
end

function EnemyService:GetHighestThreatTarget(enemy: Model): Player?
	local data = enemyData[enemy]
	if not data then return nil end
	
	local highestThreat = 0
	local highestTarget = nil
	
	for player, threat in pairs(data.ThreatTable) do
		if player.Parent and player.Character and player.Character:FindFirstChild("Humanoid") then
			local hum = player.Character.Humanoid
			if hum.Health > 0 and threat > highestThreat then
				highestThreat = threat
				highestTarget = player
			end
		else
			data.ThreatTable[player] = nil
		end
	end
	
	return highestTarget
end

--===============================
-- TELEGRAPH SYSTEM
--===============================

function EnemyService:TelegraphAttack(enemy: Model, targetPosition: Vector3, duration: number, attackType: string?)
	local root = enemy:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	enemy:SetAttribute("Telegraphing", true)
	
	local EnemyTelegraph = Remotes.GetEvent("EnemyTelegraph")
	if EnemyTelegraph then
		EnemyTelegraph:FireAllClients({
			enemyId = enemy:GetFullName(),
			position = targetPosition,
			attackType = attackType or "melee",
			duration = duration,
			radius = enemy:GetAttribute("IsElite") and 8 or 5,
		})
	end
	
	-- Create ground indicator
	local indicator = Instance.new("Part")
	indicator.Name = "TelegraphIndicator"
	indicator.Anchored = true
	indicator.CanCollide = false
	indicator.Size = Vector3.new(enemy:GetAttribute("IsElite") and 16 or 10, 0.2, enemy:GetAttribute("IsElite") and 16 or 10)
	indicator.Position = Vector3.new(targetPosition.X, targetPosition.Y - 1, targetPosition.Z)
	indicator.Color = Color3.fromRGB(255, 50, 50)
	indicator.Material = Enum.Material.Neon
	indicator.Transparency = 0.5
	indicator.Shape = Enum.PartType.Cylinder
	indicator.CFrame = CFrame.new(indicator.Position) * CFrame.Angles(0, 0, math.rad(90))
	indicator.Parent = Workspace
	
	task.delay(duration, function()
		if indicator and indicator.Parent then
			indicator:Destroy()
		end
		if enemy and enemy.Parent then
			enemy:SetAttribute("Telegraphing", false)
		end
	end)
	
	return indicator
end

--===============================
-- ELITE & MINI-BOSS CREATION (Updated per task)
--===============================

function EnemyService:MakeElite(enemy: Model, humanoid: Humanoid)
	enemy:SetAttribute("IsElite", true)
	-- Rename with Elite_ prefix
	enemy.Name = "Elite_" .. enemy.Name
	
	-- 3x health, 2x rewards per task spec
	humanoid.MaxHealth = humanoid.MaxHealth * 3
	humanoid.Health = humanoid.MaxHealth
	enemy:SetAttribute("Damage", math.floor(enemy:GetAttribute("Damage") * 1.5))
	enemy:SetAttribute("ExpReward", math.floor(enemy:GetAttribute("ExpReward") * 2))
	
	-- Unique attack patterns for elites
	enemy:SetAttribute("EliteAttackPattern", math.random(1, 3))
	
	-- Glowing effect
	local root = enemy:FindFirstChild("HumanoidRootPart")
	if root then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 215, 0)
		light.Brightness = 2
		light.Range = 12
		light.Parent = root
		
		-- Scale up
		root.Size = root.Size * 1.3
	end
end

function EnemyService:CreateMiniBoss(name: string, position: Vector3)
	local healthMult, damageMult, speedMult = self:GetDifficultyMultipliers(position)
	
	local model = Instance.new("Model")
	model.Name = name .. " (Mini-Boss)"
	model:SetAttribute("IsMiniBoss", true)
	model:SetAttribute("ExpReward", math.floor(500 * healthMult))
	model:SetAttribute("State", STATE_IDLE)
	model:SetAttribute("HomePosition", position)
	model:SetAttribute("PatrolTarget", Vector3.zero)
	model:SetAttribute("LastAttack", 0)
	model:SetAttribute("LastMove", 0)
	model:SetAttribute("LastPatrolChange", 0)
	model:SetAttribute("Damage", math.floor(40 * damageMult))
	model:SetAttribute("AttackPattern", 1) -- Tracks multi-hit patterns
	model:SetAttribute("Telegraphing", false)
	model:SetAttribute("AggroRange", 60)
	
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = math.floor(2000 * healthMult)
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = math.floor(14 * speedMult)
	humanoid.Parent = model
	
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(8, 8, 8)
	rootPart.Position = position
	rootPart.Color = Color3.fromRGB(180, 0, 255)
	rootPart.Material = Enum.Material.Neon
	rootPart.Anchored = false
	rootPart.CanCollide = true
	rootPart.Parent = model
	
	-- Mini-boss glow
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(180, 0, 255)
	light.Brightness = 3
	light.Range = 20
	light.Parent = rootPart
	
	model.PrimaryPart = rootPart
	model.Parent = self.EnemyFolder
	
	initEnemyData(model)
	addToGrid(model)
	self:CreateHealthBar(model)
	
	print("[EnemyService] Spawned Mini-Boss: " .. model.Name)
	return model
end

--===============================
-- ENEMY SPAWNING
--===============================

function EnemyService:Init()
	print("[EnemyService] Initializing...")
	
	local enemyFolder = Workspace:FindFirstChild(ENEMY_FOLDER_NAME) or Instance.new("Folder")
	enemyFolder.Name = ENEMY_FOLDER_NAME
	enemyFolder.Parent = Workspace
	self.EnemyFolder = enemyFolder
end

function EnemyService:Start()
	print("[EnemyService] Starting...")
	
	-- Spawn loop
	task.spawn(function()
		while true do
			local enemyCount = 0
			for _, child in ipairs(self.EnemyFolder:GetChildren()) do
				if not child:GetAttribute("IsBoss") and not child:GetAttribute("IsMiniBoss") then
					enemyCount = enemyCount + 1
				end
			end

			if enemyCount < 15 then
				local zone = Constants.ZONES["Glitch Wastes"]
				if zone then
					local x = math.random(-50, 50)
					local z = math.random(150, 600) -- Extended range
					local spawnPos = Vector3.new(x, 5, z)
					
					-- Check for mini-boss spawn
					if self:ShouldSpawnMiniBoss(spawnPos) then
						self:CreateMiniBoss("Glitch Sentinel", spawnPos)
					else
						self:SpawnEnemy("Glitch Slime", spawnPos)
					end
				end
			end
			
			-- Boss Spawning
			local bossExists = false
			for _, child in ipairs(self.EnemyFolder:GetChildren()) do
				if child:GetAttribute("IsBoss") then
					bossExists = true
					break
				end
			end
			
			if not bossExists then
				self:SpawnBoss("Glitch King", Vector3.new(0, 5, 450))
			end
			
			task.wait(5)
		end
	end)
	
	-- AI Loop with performance optimization
	local lastUpdateTime = {}
	maid:GiveTask(RunService.Heartbeat:Connect(function()
		self:UpdateEnemies(lastUpdateTime)
	end))
end

function EnemyService:SpawnBoss(name: string, position: Vector3)
	local bossDef = Constants.BOSSES.GlitchKing
	if not bossDef then return end

	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("IsBoss", true)
	model:SetAttribute("ExpReward", bossDef.Rewards.Exp)
	model:SetAttribute("Passive", true)
	model:SetAttribute("AggroRange", 100)
	model:SetAttribute("State", STATE_IDLE)
	model:SetAttribute("LastAttack", 0)
	model:SetAttribute("LastMove", 0)
	model:SetAttribute("Damage", bossDef.Damage)
	model:SetAttribute("Telegraphing", false)
	
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 50000 -- Phase 40: Set to 50000
	humanoid.Health = 50000
	humanoid.Parent = model
	
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(10, 15, 10)
	rootPart.Position = position
	rootPart.Color = Color3.fromRGB(50, 0, 50)
	rootPart.Material = Enum.Material.Neon
	rootPart.Anchored = false
	rootPart.CanCollide = true
	rootPart.Parent = model
	
	model.PrimaryPart = rootPart
	model.Parent = self.EnemyFolder
	
	-- Phase 40: Scale the model to 4.0
	model:ScaleTo(4.0)
	
	-- Phase 40: Add BillboardGui with boss name
	local bossLabel = Instance.new("BillboardGui")
	bossLabel.Name = "BossNameLabel"
	bossLabel.Adornee = rootPart
	bossLabel.Size = UDim2.new(0, 300, 0, 50)
	bossLabel.StudsOffset = Vector3.new(0, 12, 0)
	bossLabel.AlwaysOnTop = true
	bossLabel.Parent = rootPart
	
	local nameText = Instance.new("TextLabel")
	nameText.Name = "NameText"
	nameText.Size = UDim2.new(1, 0, 1, 0)
	nameText.BackgroundTransparency = 1
	nameText.Text = "☠️ THE GLITCH KING ☠️"
	nameText.TextColor3 = Color3.fromRGB(255, 0, 0)
	nameText.TextStrokeTransparency = 0
	nameText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameText.Font = Enum.Font.GothamBold
	nameText.TextSize = 30
	nameText.Parent = bossLabel
	
	initEnemyData(model)
	addToGrid(model)
	
	local BossSpawned = Remotes.GetEvent("BossSpawned")
	if BossSpawned then
		BossSpawned:FireAllClients({Name = name, MaxHealth = 50000})
	end
	
	print("[EnemyService] Spawned Boss: " .. name .. " with scale 4.0 and 50000 HP")
end

function EnemyService:SpawnEnemy(name: string, position: Vector3)
	local healthMult, damageMult, speedMult = self:GetDifficultyMultipliers(position)
	local baseHealth = 100
	local baseDamage = 15
	local baseSpeed = 12
	
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("ExpReward", math.floor(25 * healthMult))
	model:SetAttribute("State", STATE_IDLE)
	model:SetAttribute("HomePosition", position)
	model:SetAttribute("PatrolTarget", Vector3.zero)
	model:SetAttribute("LastAttack", 0)
	model:SetAttribute("LastMove", 0)
	model:SetAttribute("LastPatrolChange", 0)
	model:SetAttribute("Damage", math.floor(baseDamage * damageMult))
	model:SetAttribute("Telegraphing", false)
	model:SetAttribute("AggroRange", 40)
	
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = math.floor(baseHealth * healthMult)
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = math.floor(baseSpeed * speedMult)
	humanoid.Parent = model
	
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(4, 4, 4)
	rootPart.Position = position
	rootPart.Color = Color3.fromRGB(100, 0, 255)
	rootPart.Material = Enum.Material.Neon
	rootPart.Anchored = false
	rootPart.CanCollide = true
	rootPart.Parent = model
	
	-- Procedural visuals
	rootPart.Shape = Enum.PartType.Ball
	rootPart.Transparency = 0.3
	
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Size = Vector3.new(2, 2, 2)
	core.Shape = Enum.PartType.Ball
	core.Color = Color3.fromRGB(50, 0, 150)
	core.Material = Enum.Material.Neon
	core.CanCollide = false
	core.Massless = true
	core.Parent = model
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = core
	weld.Parent = core
	core.CFrame = rootPart.CFrame
	
	model.PrimaryPart = rootPart
	model.Parent = self.EnemyFolder
	
	initEnemyData(model)
	addToGrid(model)
	
	-- Elite chance
	if math.random() < ELITE_SPAWN_CHANCE then
		self:MakeElite(model, humanoid)
	end
	
	self:CreateHealthBar(model)
end

function EnemyService:CreateHealthBar(model)
	local humanoid = model:FindFirstChild("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end
	
	local bg = Instance.new("BillboardGui")
	bg.Name = "HealthBarGui"
	bg.Adornee = root
	bg.Size = UDim2.new(4, 0, 0.5, 0)
	bg.StudsOffset = Vector3.new(0, 3, 0)
	bg.AlwaysOnTop = true
	bg.Parent = root
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 0
	frame.Parent = bg
	
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = model:GetAttribute("IsElite") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 50, 50)
	fill.BorderSizePixel = 0
	fill.Parent = frame
	
	-- Elite/Mini-boss label
	if model:GetAttribute("IsElite") or model:GetAttribute("IsMiniBoss") then
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.Position = UDim2.new(0, 0, -1.5, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 215, 0)
		label.TextScaled = true
		label.Text = model:GetAttribute("IsMiniBoss") and "★ MINI-BOSS ★" or "★ ELITE ★"
		label.Font = Enum.Font.GothamBold
		label.Parent = bg
	end
	
	local data = enemyData[model]
	if data then
		data.Maid:GiveTask(humanoid.HealthChanged:Connect(function(health)
			local percent = health / humanoid.MaxHealth
			fill:TweenSize(UDim2.new(percent, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
		end))
	end
end

--===============================
-- PATHFINDING FOR PATROL
--===============================

function EnemyService:ComputePatrolPath(enemy: Model, humanoid: Humanoid, targetPos: Vector3)
	local rootPart = enemy:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = false,
	})
	
	local success, errorMessage = pcall(function()
		path:ComputeAsync(rootPart.Position, targetPos)
	end)
	
	if success and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		for _, waypoint in ipairs(waypoints) do
			humanoid:MoveTo(waypoint.Position)
			humanoid.MoveToFinished:Wait()
			
			-- Break if state changed
			if enemy:GetAttribute("State") ~= STATE_PATROL then
				break
			end
		end
	else
		-- Fallback to direct movement
		humanoid:MoveTo(targetPos)
	end
end

--===============================
-- AI UPDATE LOOP
--===============================

function EnemyService:GetUpdateInterval(enemy: Model): number
	local root = enemy:FindFirstChild("HumanoidRootPart")
	if not root then return 1 end
	
	local nearestDistance = math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character.PrimaryPart then
			local dist = (player.Character.PrimaryPart.Position - root.Position).Magnitude
			if dist < nearestDistance then
				nearestDistance = dist
			end
		end
	end
	
	for _, config in ipairs(UPDATE_FREQUENCIES) do
		if nearestDistance <= config.MaxDistance then
			return config.Interval
		end
	end
	
	return 1
end

function EnemyService:UpdateEnemies(lastUpdateTime)
	local now = os.clock()
	
	for _, enemy in ipairs(self.EnemyFolder:GetChildren()) do
		if not enemy:IsA("Model") then continue end
		
		-- Performance: Check update interval
		local interval = self:GetUpdateInterval(enemy)
		local lastTime = lastUpdateTime[enemy] or 0
		if now - lastTime < interval then continue end
		lastUpdateTime[enemy] = now
		
		local humanoid = enemy:FindFirstChild("Humanoid")
		local rootPart = enemy:FindFirstChild("HumanoidRootPart")
		
		if humanoid and rootPart and humanoid.Health > 0 then
			-- Update grid position
			updateGridPosition(enemy)
			
			-- Safety check
			if rootPart.Position.Y < -100 or rootPart.Position.Z < 100 then
				cleanupEnemyData(enemy)
				removeFromGrid(enemy)
				enemy:Destroy()
				continue
			end
			
			-- Boss logic
			if enemy:GetAttribute("IsBoss") then
				self:UpdateBoss(enemy, humanoid, rootPart, now)
				continue
			end
			
			-- Mini-boss logic
			if enemy:GetAttribute("IsMiniBoss") then
				self:UpdateMiniBoss(enemy, humanoid, rootPart, now)
				continue
			end
			
			-- Regular enemy state machine
			self:UpdateRegularEnemy(enemy, humanoid, rootPart, now)
			
		elseif humanoid and humanoid.Health <= 0 then
			if not enemy:GetAttribute("Dead") then
				enemy:SetAttribute("Dead", true)
				self:HandleEnemyDeath(enemy)
			end
		else
			cleanupEnemyData(enemy)
			removeFromGrid(enemy)
			enemy:Destroy()
		end
	end
end

function EnemyService:UpdateRegularEnemy(enemy: Model, humanoid: Humanoid, rootPart: BasePart, now: number)
	-- Get target from threat table or nearest player
	local target = self:GetHighestThreatTarget(enemy) or self:FindNearestPlayer(rootPart.Position)
	local distanceToTarget = math.huge
	local targetPos = nil
	
	if target and target.Character and target.Character.PrimaryPart then
		targetPos = target.Character.PrimaryPart.Position
		distanceToTarget = (targetPos - rootPart.Position).Magnitude
	end
	
	local state = enemy:GetAttribute("State") or STATE_IDLE
	local homePos = enemy:GetAttribute("HomePosition") or rootPart.Position
	local healthPercent = humanoid.Health / humanoid.MaxHealth
	local aggroRange = enemy:GetAttribute("AggroRange") or AGGRO_RANGE
	
	-- State Transitions (Updated: retreat at 25%)
	if healthPercent < RETREAT_HEALTH_THRESHOLD then
		state = STATE_RETREAT
	elseif state == STATE_IDLE then
		if target and distanceToTarget < aggroRange then
			state = STATE_AGGRO
			self:AddThreat(enemy, target, 1) -- Initial aggro
		elseif math.random() < 0.01 then -- Small chance to patrol
			state = STATE_PATROL
		end
	elseif state == STATE_PATROL then
		if target and distanceToTarget < aggroRange then
			state = STATE_AGGRO
			self:AddThreat(enemy, target, 1)
		end
	elseif state == STATE_AGGRO then
		if not target or distanceToTarget > aggroRange * 1.5 then
			state = STATE_IDLE
		elseif distanceToTarget < 8 then
			state = STATE_ATTACK
		end
	elseif state == STATE_ATTACK then
		if not target or distanceToTarget > 10 then
			state = STATE_AGGRO
		end
	elseif state == STATE_RETREAT then
		if healthPercent >= 0.3 then
			state = STATE_IDLE
		end
	end
	
	enemy:SetAttribute("State", state)
	
	-- State Behaviors
	if state == STATE_IDLE then
		self:DoIdleBehavior(enemy, humanoid, rootPart, homePos, now)
	elseif state == STATE_PATROL then
		self:DoPatrolBehavior(enemy, humanoid, rootPart, homePos, now)
	elseif state == STATE_AGGRO then
		self:DoAggroBehavior(enemy, humanoid, rootPart, targetPos, now)
	elseif state == STATE_ATTACK then
		self:DoAttackBehavior(enemy, humanoid, rootPart, target, targetPos, now)
	elseif state == STATE_RETREAT then
		self:DoRetreatBehavior(enemy, humanoid, rootPart, targetPos, homePos, now)
	end
end

function EnemyService:DoIdleBehavior(enemy, humanoid, rootPart, homePos, now)
	-- Small random wandering
	if now - (enemy:GetAttribute("LastMove") or 0) > 2 then
		local angle = math.random() * math.pi * 2
		local dist = math.random(3, 8)
		local wanderPos = homePos + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		humanoid:MoveTo(wanderPos)
		enemy:SetAttribute("LastMove", now)
	end
end

function EnemyService:DoPatrolBehavior(enemy, humanoid, rootPart, homePos, now)
	local patrolTarget = enemy:GetAttribute("PatrolTarget")
	local lastPatrolChange = enemy:GetAttribute("LastPatrolChange") or 0
	
	if not patrolTarget or patrolTarget == Vector3.zero 
		or (rootPart.Position - patrolTarget).Magnitude < 5
		or (now - lastPatrolChange > math.random(8, 15)) then
		
		local angle = math.random() * math.pi * 2
		local distance = math.random(15, 30)
		patrolTarget = homePos + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
		enemy:SetAttribute("PatrolTarget", patrolTarget)
		enemy:SetAttribute("LastPatrolChange", now)
	end
	
	if now - (enemy:GetAttribute("LastMove") or 0) > 0.5 then
		-- Use PathfindingService for waypoint-based movement
		task.spawn(function()
			self:ComputePatrolPath(enemy, humanoid, patrolTarget)
		end)
		enemy:SetAttribute("LastMove", now)
	end
end

function EnemyService:DoAggroBehavior(enemy, humanoid, rootPart, targetPos, now)
	if targetPos and now - (enemy:GetAttribute("LastMove") or 0) > 0.2 then
		humanoid:MoveTo(targetPos)
		enemy:SetAttribute("LastMove", now)
	end
end

function EnemyService:DoAttackBehavior(enemy, humanoid, rootPart, target, targetPos, now)
	humanoid:MoveTo(rootPart.Position) -- Stop
	
	local lastAttack = enemy:GetAttribute("LastAttack") or 0
	local isTelegraphing = enemy:GetAttribute("Telegraphing") or false
	local attackCooldown = enemy:GetAttribute("IsElite") and 1.5 or 2
	
	if not isTelegraphing and now - lastAttack > attackCooldown and targetPos then
		local telegraphDuration = Constants.ENEMY.TELEGRAPH_DURATION or 0.5
		self:TelegraphAttack(enemy, targetPos, telegraphDuration, "melee")
		
		task.delay(telegraphDuration, function()
			if enemy.Parent and humanoid.Health > 0 and target and target.Character then
				local tHum = target.Character:FindFirstChild("Humanoid")
				local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
				if tHum and tRoot and (tRoot.Position - rootPart.Position).Magnitude < 12 then
					local damage = enemy:GetAttribute("Damage") or 15
					tHum:TakeDamage(damage)
					self:AddThreat(enemy, target, damage)
				end
			end
		end)
		enemy:SetAttribute("LastAttack", now)
	end
end

function EnemyService:DoRetreatBehavior(enemy, humanoid, rootPart, targetPos, homePos, now)
	if targetPos and now - (enemy:GetAttribute("LastMove") or 0) > 0.2 then
		local fleeDirection = (rootPart.Position - targetPos).Unit
		local fleeTarget = rootPart.Position + fleeDirection * 30
		humanoid:MoveTo(fleeTarget)
		enemy:SetAttribute("LastMove", now)
	elseif now - (enemy:GetAttribute("LastMove") or 0) > 0.5 then
		humanoid:MoveTo(homePos)
		enemy:SetAttribute("LastMove", now)
	end
end

--===============================
-- MINI-BOSS AI
--===============================

function EnemyService:UpdateMiniBoss(enemy: Model, humanoid: Humanoid, rootPart: BasePart, now: number)
	local target = self:GetHighestThreatTarget(enemy) or self:FindNearestPlayer(rootPart.Position)
	local distanceToTarget = math.huge
	local targetPos = nil
	
	if target and target.Character and target.Character.PrimaryPart then
		targetPos = target.Character.PrimaryPart.Position
		distanceToTarget = (targetPos - rootPart.Position).Magnitude
	end
	
	local aggroRange = enemy:GetAttribute("AggroRange") or 60
	
	if target and distanceToTarget < aggroRange then
		-- Chase
		if distanceToTarget > 10 then
			if now - (enemy:GetAttribute("LastMove") or 0) > 0.15 then
				humanoid:MoveTo(targetPos)
				enemy:SetAttribute("LastMove", now)
			end
		else
			-- Attack with patterns
			humanoid:MoveTo(rootPart.Position)
			local lastAttack = enemy:GetAttribute("LastAttack") or 0
			local isTelegraphing = enemy:GetAttribute("Telegraphing") or false
			
			if not isTelegraphing and now - lastAttack > 2.5 and targetPos then
				local pattern = enemy:GetAttribute("AttackPattern") or 1
				
				if pattern == 1 then
					-- Multi-hit: 3 quick attacks
					self:TelegraphAttack(enemy, targetPos, 0.3, "multi")
					for i = 0, 2 do
						task.delay(0.3 + i * 0.4, function()
							if enemy.Parent and humanoid.Health > 0 and target and target.Character then
								local tHum = target.Character:FindFirstChild("Humanoid")
								local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
								if tHum and tRoot and (tRoot.Position - rootPart.Position).Magnitude < 15 then
									tHum:TakeDamage(enemy:GetAttribute("Damage") * 0.5)
									self:AddThreat(enemy, target, 10)
								end
							end
						end)
					end
					enemy:SetAttribute("AttackPattern", 2)
				else
					-- AoE slam
					self:TelegraphAttack(enemy, rootPart.Position, 0.8, "aoe")
					task.delay(0.8, function()
						if enemy.Parent and humanoid.Health > 0 then
							for _, player in ipairs(Players:GetPlayers()) do
								if player.Character and player.Character.PrimaryPart then
									local pRoot = player.Character.PrimaryPart
									if (pRoot.Position - rootPart.Position).Magnitude < 20 then
										local pHum = player.Character:FindFirstChild("Humanoid")
										if pHum then
											pHum:TakeDamage(enemy:GetAttribute("Damage") * 1.5)
											self:AddThreat(enemy, player, 20)
										end
									end
								end
							end
						end
					end)
					enemy:SetAttribute("AttackPattern", 1)
				end
				enemy:SetAttribute("LastAttack", now)
			end
		end
	else
		-- Idle patrol
		self:DoPatrolBehavior(enemy, humanoid, rootPart, enemy:GetAttribute("HomePosition") or rootPart.Position, now)
	end
end

--===============================
-- BOSS AI
--===============================

function EnemyService:UpdateBoss(enemy, humanoid, rootPart, now)
	local isPassive = enemy:GetAttribute("Passive")
	
	local target = self:GetHighestThreatTarget(enemy) or self:FindNearestPlayer(rootPart.Position)
	local distance = math.huge
	
	if target and target.Character and target.Character.PrimaryPart then
		distance = (target.Character.PrimaryPart.Position - rootPart.Position).Magnitude
	end
	
	if isPassive then
		if humanoid.Health < humanoid.MaxHealth or distance < 30 then
			enemy:SetAttribute("Passive", false)
		end
		return
	end
	
	local aggroRange = enemy:GetAttribute("AggroRange") or 100
	if distance < aggroRange and target then
		local targetPos = target.Character.PrimaryPart.Position
		
		if now - (enemy:GetAttribute("LastMove") or 0) > 0.1 then
			humanoid:MoveTo(targetPos)
			enemy:SetAttribute("LastMove", now)
		end
		
		if distance < 15 then
			local lastAttack = enemy:GetAttribute("LastAttack") or 0
			local isTelegraphing = enemy:GetAttribute("Telegraphing") or false
			
			if not isTelegraphing and now - lastAttack > 2 then
				self:TelegraphAttack(enemy, targetPos, 0.6, "boss_slam")
				
				task.delay(0.6, function()
					if enemy.Parent and humanoid.Health > 0 and target and target.Character then
						local tHum = target.Character:FindFirstChild("Humanoid")
						if tHum then
							tHum:TakeDamage(enemy:GetAttribute("Damage") or 50)
							self:AddThreat(enemy, target, 50)
						end
					end
				end)
				enemy:SetAttribute("LastAttack", now)
			end
		end
	end
	
	local BossUpdate = Remotes.GetEvent("BossUpdate")
	if BossUpdate then
		BossUpdate:FireAllClients(humanoid.Health, humanoid.MaxHealth)
	end
end

--===============================
-- UTILITY
--===============================

function EnemyService:FindNearestPlayer(position: Vector3): Player?
	local nearestPlayer = nil
	local minDistance = math.huge
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character.PrimaryPart then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local distance = (player.Character.PrimaryPart.Position - position).Magnitude
				if distance < minDistance then
					minDistance = distance
					nearestPlayer = player
				end
			end
		end
	end
	
	return nearestPlayer
end

function EnemyService:HandleEnemyDeath(enemy: Model)
	local rootPart = enemy:FindFirstChild("HumanoidRootPart")
	if not rootPart then 
		cleanupEnemyData(enemy)
		removeFromGrid(enemy)
		enemy:Destroy()
		return 
	end
	
	if enemy:GetAttribute("IsBoss") then
		local BossDefeated = Remotes.GetEvent("BossDefeated")
		if BossDefeated then
			BossDefeated:FireAllClients()
		end
	end
	
	-- Find killer from threat table
	local killer = self:GetHighestThreatTarget(enemy) or self:FindNearestPlayer(rootPart.Position)
	if killer then
		local exp = enemy:GetAttribute("ExpReward") or 10
		
		-- Elite bonus rewards
		if enemy:GetAttribute("IsElite") then
			exp = math.floor(exp * 1.5)
		end
		
		SpiritService:AddExp(killer, exp)
		QuestService:OnEnemyKilled(killer, enemy.Name)
	end
	
	cleanupEnemyData(enemy)
	removeFromGrid(enemy)
	
	task.delay(1, function()
		if enemy and enemy.Parent then
			enemy:Destroy()
		end
	end)
end

return EnemyService
