--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local SpiritService = require(script.Parent.SpiritService)

local EnemyService = {}
local enemies = {}
local ENEMY_FOLDER_NAME = "Enemies"

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
			if #self.EnemyFolder:GetChildren() < 5 then
				self:SpawnEnemy("Glitch Slime", Vector3.new(math.random(-50, 50), 5, math.random(-50, 50)))
			end
			task.wait(5)
		end
	end)
	
	-- AI Loop
	RunService.Heartbeat:Connect(function()
		self:UpdateEnemies()
	end)
end

function EnemyService:SpawnEnemy(name: string, position: Vector3)
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("ExpReward", 25) -- Base XP reward
	
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
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
	
	model.PrimaryPart = rootPart
	model.Parent = self.EnemyFolder
	
	-- Add a simple visual face or something?
	
	print("[EnemyService] Spawned " .. name)
end

function EnemyService:UpdateEnemies()
	for _, enemy in ipairs(self.EnemyFolder:GetChildren()) do
		local humanoid = enemy:FindFirstChild("Humanoid")
		local rootPart = enemy:FindFirstChild("HumanoidRootPart")
		
		if humanoid and rootPart then
			if humanoid.Health <= 0 then
				if not enemy:GetAttribute("Dead") then
					enemy:SetAttribute("Dead", true)
					self:HandleEnemyDeath(enemy)
				end
				continue
			end
			
			local target = self:FindNearestPlayer(rootPart.Position)
			if target and target.Character and target.Character.PrimaryPart then
				local targetPos = target.Character.PrimaryPart.Position
				local distance = (targetPos - rootPart.Position).Magnitude
				
				if distance < 50 then
					humanoid:MoveTo(targetPos)
					
					-- Simple attack logic
					if distance < 5 then
						-- Deal damage to player?
						-- For now just print
						-- print(enemy.Name .. " is attacking " .. target.Name)
					end
				end
			end
		end
	end
end

function EnemyService:FindNearestPlayer(position: Vector3): Player?
	local nearestPlayer = nil
	local minDistance = math.huge
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character.PrimaryPart then
			local distance = (player.Character.PrimaryPart.Position - position).Magnitude
			if distance < minDistance then
				minDistance = distance
				nearestPlayer = player
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
	
	-- Find killer (nearest player for now)
	local killer = self:FindNearestPlayer(rootPart.Position)
	if killer then
		local exp = enemy:GetAttribute("ExpReward") or 10
		SpiritService:AddExp(killer, exp)
		print(`[EnemyService] {killer.Name} killed {enemy.Name} and gained {exp} XP!`)
	end
	
	-- Visual effect?
	
	task.delay(1, function()
		if enemy and enemy.Parent then
			enemy:Destroy()
		end
	end)
end

return EnemyService
