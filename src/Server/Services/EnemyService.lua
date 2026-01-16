--!strict
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
				-- Strict Zoning: Spawn only within the Combat Zone
				local angle = math.random() * math.pi * 2
				local radius = math.random() * COMBAT_ZONE_RADIUS
				local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
				local spawnPos = COMBAT_ZONE_CENTER + offset
				
				self:SpawnEnemy("Glitch Slime", spawnPos)
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
	model:SetAttribute("LastAttack", 0)
	model:SetAttribute("LastMove", 0)
	
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
	
	print("[EnemyService] Spawned " .. name)
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
					-- Throttle movement updates
					local lastMove = enemy:GetAttribute("LastMove") or 0
					if now - lastMove > 0.2 then
						humanoid:MoveTo(targetPos)
						enemy:SetAttribute("LastMove", now)
					end
					
					-- Simple attack logic
					if distance < 6 then
						local lastAttack = enemy:GetAttribute("LastAttack") or 0
						if now - lastAttack > 1.5 then -- 1.5s cooldown
							-- Deal damage to player
							local targetHumanoid = target.Character:FindFirstChild("Humanoid")
							if targetHumanoid then
								targetHumanoid:TakeDamage(10)
								enemy:SetAttribute("LastAttack", now)
								-- Optional: Play animation or sound here
							end
						end
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
		
		-- Notify QuestService
		QuestService:OnEnemyKilled(killer, enemy.Name)
		
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
