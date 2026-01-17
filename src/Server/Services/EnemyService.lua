--[!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local SpiritService = require(script.Parent.SpiritService)
local QuestService = require(script.Parent.QuestService)

local EnemyService = {}
local enemies = {}
local ENEMY_FOLDER_NAME = "Enemies"
local COMBAT_ZONE_CENTER = Vector3.new(0, 5, 0)
local COMBAT_ZONE_RADIUS = 100

local STATE_IDLE = "Idle"
local STATE_ALERT = "Alert"
local STATE_CHASE = "Chase"
local STATE_ATTACK = "Attack"
local STATE_FLEE = "Flee"

local SPAWN_ORIGIN = Vector3.new(0, 0, 0)

function EnemyService:GetZoneDifficulty(position: Vector3): number
	local distance = (Vector3.new(position.X, 0, position.Z) - Vector3.new(SPAWN_ORIGIN.X, 0, SPAWN_ORIGIN.Z)).Magnitude
	
	for _, zone in ipairs(Constants.ENEMY.ZONE_DIFFICULTY_MULTIPLIERS) do
		if distance <= zone.MaxDistance then
			return zone.Multiplier
		end
	end
	
	return 3.0 -- Default to highest multiplier
end

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
			-- Regular Enemies
			local enemyCount = 0
			for _, child in ipairs(self.EnemyFolder:GetChildren()) do
				if not child:GetAttribute("IsBoss") then
					enemyCount = enemyCount + 1
				end
			end

			if enemyCount < 10 then
				-- Spawn in Glitch Wastes (The Wilds: Z 150-350)
				local zone = Constants.ZONES["Glitch Wastes"]
				if zone then
					-- Updated Spawn Coordinates for Platform Extension
					local x = math.random(-50, 50)
					local z = math.random(150, 350)
					local spawnPos = Vector3.new(x, 5, z)
					
					self:SpawnEnemy("Glitch Slime", spawnPos)
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
				local zone = Constants.ZONES["Glitch Wastes"]
				if zone then
					-- Spawn boss at specific position (The Throne: Z=450)
					self:SpawnBoss("Glitch King", Vector3.new(0, 5, 450))
				end
			end
			
			task.wait(5)
		end
	end)
	
	-- AI Loop
	RunService.Heartbeat:Connect(function()
		self:UpdateEnemies()
	end)
end

function EnemyService:SpawnBoss(name: string, position: Vector3)
	local bossDef = Constants.BOSSES.GlitchKing -- Simplified lookup
	if not bossDef then return end

	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("IsBoss", true)
	model:SetAttribute("ExpReward", bossDef.Rewards.Exp)
	model:SetAttribute("Passive", true) -- Starts passive
	model:SetAttribute("AggroRange", 100)
	model:SetAttribute("State", STATE_IDLE)
	model:SetAttribute("LastAttack", 0)
	model:SetAttribute("LastMove", 0)
	
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = bossDef.Health
	humanoid.Health = bossDef.Health
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
	
	-- Notify clients
	local BossSpawned = Remotes.GetEvent("BossSpawned")
	if BossSpawned then
		BossSpawned:FireAllClients({Name = name, MaxHealth = bossDef.Health})
	end
	
	print("[EnemyService] Spawned Boss: " .. name)
end

function EnemyService:SpawnEnemy(name: string, position: Vector3)
	local difficultyMultiplier = self:GetZoneDifficulty(position)
	local baseHealth = 100
	local baseDamage = 15
	
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("ExpReward", math.floor(25 * difficultyMultiplier))
	model:SetAttribute("State", STATE_IDLE)
	model:SetAttribute("HomePosition", position)
	model:SetAttribute("PatrolTarget", Vector3.zero)
	model:SetAttribute("LastAttack", 0)
	model:SetAttribute("LastMove", 0)
	model:SetAttribute("LastPatrolChange", 0)
	model:SetAttribute("Damage", math.floor(baseDamage * difficultyMultiplier))
	model:SetAttribute("AlertStart", 0)
	model:SetAttribute("Telegraphing", false)
	
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = math.floor(baseHealth * difficultyMultiplier)
	humanoid.Health = humanoid.MaxHealth
	humanoid.Parent = model
	
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(4, 4, 4)
	rootPart.Position = position
	rootPart.Color = Color3.fromRGB(100, 0, 255) -- Glitchy purple
	rootPart.Material = Enum.Material.Neon
	rootPart.Anchored = false
	rootPart.CanCollide = true
	rootPart.Parent = model
	
	-- Check for asset
	local assetId = Constants.ASSETS.ENEMIES.GlitchSlime
	if assetId and assetId ~= "rbxassetid://0" and assetId ~= "" then
		-- Real asset logic would go here
	else
		-- Procedural Slime Visuals
		-- Make it look a bit more like a slime (rounded, maybe slightly transparent)
		rootPart.Shape = Enum.PartType.Ball
		rootPart.Transparency = 0.3
		
		-- Add a "core"
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
		
		-- Align core to root
		core.CFrame = rootPart.CFrame
		
		-- Add eyes
		local leftEye = Instance.new("Part")
		leftEye.Name = "LeftEye"
		leftEye.Size = Vector3.new(0.5, 0.5, 0.2)
		leftEye.Color = Color3.new(1, 1, 1)
		leftEye.Material = Enum.Material.Neon
		leftEye.CanCollide = false
		leftEye.Parent = model
		
		local rightEye = leftEye:Clone()
		rightEye.Name = "RightEye"
		rightEye.Parent = model
		
		local weldL = Instance.new("Weld")
		weldL.Part0 = rootPart
		weldL.Part1 = leftEye
		weldL.C0 = CFrame.new(-1, 0.5, -1.8)
		weldL.Parent = leftEye
		
		local weldR = Instance.new("Weld")
		weldR.Part0 = rootPart
		weldR.Part1 = rightEye
		weldR.C0 = CFrame.new(1, 0.5, -1.8)
		weldR.Parent = rightEye
	end
	
	model.PrimaryPart = rootPart
	model.Parent = self.EnemyFolder
	
	self:CreateHealthBar(model)
	
	-- print("[EnemyService] Spawned " .. name .. " with difficulty " .. difficultyMultiplier)
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
	fill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	fill.BorderSizePixel = 0
	fill.Parent = frame
	
	humanoid.HealthChanged:Connect(function(health)
		local percent = health / humanoid.MaxHealth
		fill:TweenSize(UDim2.new(percent, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
	end)
end

function EnemyService:UpdateEnemies()
	local now = os.clock()
	
	for _, enemy in ipairs(self.EnemyFolder:GetChildren()) do
		if not enemy:IsA("Model") then continue end
		
		local humanoid = enemy:FindFirstChild("Humanoid")
		local rootPart = enemy:FindFirstChild("HumanoidRootPart")
		
		if humanoid and rootPart and humanoid.Health > 0 then
			-- Safety check: Ensure enemy isn't falling into void or in Hub
			if rootPart.Position.Y < -100 or rootPart.Position.Z < 100 then
				enemy:Destroy()
				continue
			end
			
			local target = self:FindNearestPlayer(rootPart.Position)
			local distanceToTarget = math.huge
			local targetPos = nil
			
			if target and target.Character and target.Character.PrimaryPart then
				targetPos = target.Character.PrimaryPart.Position
				distanceToTarget = (targetPos - rootPart.Position).Magnitude
			end

			-- Boss Logic (Simplified State Machine for Boss)
			if enemy:GetAttribute("IsBoss") then
				self:UpdateBoss(enemy, humanoid, rootPart, target, distanceToTarget, now)
				continue
			end
			
			-- Regular Enemy State Machine
			local state = enemy:GetAttribute("State") or STATE_IDLE
			local homePos = enemy:GetAttribute("HomePosition") or rootPart.Position
			local healthPercent = humanoid.Health / humanoid.MaxHealth
			
			-- Check for Flee state (low health)
			if healthPercent < Constants.ENEMY.FLEE_HEALTH_THRESHOLD then
				state = STATE_FLEE
			-- State Transitions
			elseif state == STATE_IDLE then
				if target and distanceToTarget < 40 then
					state = STATE_ALERT
					enemy:SetAttribute("AlertStart", now)
				end
			elseif state == STATE_ALERT then
				local alertStart = enemy:GetAttribute("AlertStart") or now
				if now - alertStart > 0.5 then -- 0.5s alert duration
					state = STATE_CHASE
				elseif not target or distanceToTarget > 50 then
					state = STATE_IDLE
				end
			elseif state == STATE_CHASE then
				if not target or distanceToTarget > 60 then
					state = STATE_IDLE
				elseif distanceToTarget < 8 then
					state = STATE_ATTACK
				end
			elseif state == STATE_ATTACK then
				if not target or distanceToTarget > 10 then
					state = STATE_CHASE
				end
			elseif state == STATE_FLEE then
				if healthPercent >= Constants.ENEMY.FLEE_HEALTH_THRESHOLD then
					state = STATE_IDLE
				end
			end
			
			enemy:SetAttribute("State", state)
			
			-- State Behaviors
			if state == STATE_IDLE then
				-- Improved Patrol Logic with random wandering
				local patrolTarget = enemy:GetAttribute("PatrolTarget")
				local lastPatrolChange = enemy:GetAttribute("LastPatrolChange") or 0
				
				-- Change patrol target if reached, invalid, or timeout (random timing)
				if not patrolTarget or patrolTarget == Vector3.zero 
					or (rootPart.Position - patrolTarget).Magnitude < 5
					or (now - lastPatrolChange > math.random(5, 10)) then
					
					-- Pick new random point near home within spawn radius
					local angle = math.random() * math.pi * 2
					local distance = math.random(10, 25)
					local rx = math.cos(angle) * distance
					local rz = math.sin(angle) * distance
					patrolTarget = homePos + Vector3.new(rx, 0, rz)
					enemy:SetAttribute("PatrolTarget", patrolTarget)
					enemy:SetAttribute("LastPatrolChange", now)
				end
				
				if now - (enemy:GetAttribute("LastMove") or 0) > 0.5 then
					humanoid:MoveTo(patrolTarget)
					enemy:SetAttribute("LastMove", now)
				end
			
			elseif state == STATE_ALERT then
				-- Stop and face player (visual telegraph before engaging)
				humanoid:MoveTo(rootPart.Position)
			
			elseif state == STATE_CHASE then
				if targetPos and now - (enemy:GetAttribute("LastMove") or 0) > 0.2 then
					humanoid:MoveTo(targetPos)
					enemy:SetAttribute("LastMove", now)
				end
			
			elseif state == STATE_ATTACK then
				humanoid:MoveTo(rootPart.Position) -- Stop moving
				
				local lastAttack = enemy:GetAttribute("LastAttack") or 0
				local isTelegraphing = enemy:GetAttribute("Telegraphing") or false
				
				if not isTelegraphing and now - lastAttack > 2 then -- 2s Attack Cooldown
					enemy:SetAttribute("Telegraphing", true)
					
					-- Fire telegraph remote
					local EnemyTelegraph = Remotes.GetEvent("EnemyTelegraph")
					if EnemyTelegraph then
						EnemyTelegraph:FireAllClients({
							enemyId = enemy:GetFullName(),
							attackType = "melee",
							duration = Constants.ENEMY.TELEGRAPH_DURATION
						})
					end
					
					-- Telegraph delay then damage
					task.delay(Constants.ENEMY.TELEGRAPH_DURATION, function()
						if enemy.Parent and humanoid.Health > 0 and target and target.Character then
							local tHum = target.Character:FindFirstChild("Humanoid")
							local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
							if tHum and tRoot and (tRoot.Position - rootPart.Position).Magnitude < 12 then
								local damage = enemy:GetAttribute("Damage") or 15
								tHum:TakeDamage(damage)
							end
						end
						enemy:SetAttribute("Telegraphing", false)
					end)
					enemy:SetAttribute("LastAttack", now)
				end
			
			elseif state == STATE_FLEE then
				-- Run away from target
				if target and targetPos and now - (enemy:GetAttribute("LastMove") or 0) > 0.2 then
					local fleeDirection = (rootPart.Position - targetPos).Unit
					local fleeTarget = rootPart.Position + fleeDirection * 30
					humanoid:MoveTo(fleeTarget)
					enemy:SetAttribute("LastMove", now)
				elseif now - (enemy:GetAttribute("LastMove") or 0) > 0.5 then
					-- No target, wander towards home
					humanoid:MoveTo(homePos)
					enemy:SetAttribute("LastMove", now)
				end
			end
			
		elseif humanoid and humanoid.Health <= 0 then
			if not enemy:GetAttribute("Dead") then
				enemy:SetAttribute("Dead", true)
				self:HandleEnemyDeath(enemy)
			end
		else
			-- Cleanup invalid enemies
			enemy:Destroy()
		end
	end
end

function EnemyService:UpdateBoss(enemy, humanoid, rootPart, target, distance, now)
	local isPassive = enemy:GetAttribute("Passive")
	
	-- Wake up if damaged or player is very close
	if isPassive then
		if humanoid.Health < humanoid.MaxHealth or distance < 30 then
			enemy:SetAttribute("Passive", false)
		end
		return -- Don't move or attack while passive
	end
	
	-- Boss Movement & Attack
	local aggroRange = enemy:GetAttribute("AggroRange") or 100
	if distance < aggroRange and target then
		local targetPos = target.Character.PrimaryPart.Position
		local lastMove = enemy:GetAttribute("LastMove") or 0
		if now - lastMove > 0.1 then
			humanoid:MoveTo(targetPos)
			enemy:SetAttribute("LastMove", now)
		end
		
		if distance < 15 then
			local lastAttack = enemy:GetAttribute("LastAttack") or 0
			if now - lastAttack > 2 then
				local targetHumanoid = target.Character:FindFirstChild("Humanoid")
				if targetHumanoid then
					targetHumanoid:TakeDamage(50) -- Boss damage
					enemy:SetAttribute("LastAttack", now)
				end
			end
		end
	end
	
	-- Update Boss Bar
	local BossUpdate = Remotes.GetEvent("BossUpdate")
	if BossUpdate then
		BossUpdate:FireAllClients(humanoid.Health, humanoid.MaxHealth)
	end
end

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
		enemy:Destroy()
		return 
	end
	
	-- Boss Death Event
	if enemy:GetAttribute("IsBoss") then
		local BossDefeated = Remotes.GetEvent("BossDefeated")
		if BossDefeated then
			BossDefeated:FireAllClients()
		end
	end
	
	-- Find killer (nearest player for now)
	local killer = self:FindNearestPlayer(rootPart.Position)
	if killer then
		local exp = enemy:GetAttribute("ExpReward") or 10
		SpiritService:AddExp(killer, exp)
		
		-- Notify QuestService
		QuestService:OnEnemyKilled(killer, enemy.Name)
		
		-- print(`[EnemyService] {killer.Name} killed {enemy.Name} and gained {exp} XP!`)
	end
	
	-- Visual effect?
	
	task.delay(1, function()
		if enemy and enemy.Parent then
			enemy:Destroy()
		end
	end)
end

return EnemyService
