local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local BossService = {}
BossService.BossModel = nil
BossService.CurrentHealth = 0
BossService.MaxHealth = 0
BossService.State = "Idle" -- Idle, Active, Defeated
BossService.NextAttackTime = 0

function BossService:Init()
	print("[BossService] Initializing...")
	self.BossSpawned = Remotes.GetEvent("BossSpawned")
	self.BossUpdate = Remotes.GetEvent("BossUpdate")
	self.BossAttack = Remotes.GetEvent("BossAttack")
	self.BossDefeated = Remotes.GetEvent("BossDefeated")
end

function BossService:Start()
	print("[BossService] Starting...")
	
	-- Spawn boss after a delay
	task.delay(5, function()
		self:SpawnBoss("GlitchKing")
	end)
	
	-- Game Loop
	RunService.Heartbeat:Connect(function(dt)
		self:Update(dt)
	end)
end

function BossService:SpawnBoss(bossId)
	local bossData = Constants.BOSSES[bossId]
	if not bossData then return end
	
	print("[BossService] Spawning " .. bossData.Name)
	
	self.MaxHealth = bossData.Health
	self.CurrentHealth = self.MaxHealth
	self.State = "Active"
	self.BossId = bossId
	
	-- Create Placeholder Model
	local model = Instance.new("Model")
	model.Name = bossData.Name
	
	local part = Instance.new("Part")
	part.Name = "HumanoidRootPart"
	part.Size = Vector3.new(10, 20, 10)
	part.Position = Constants.ZONES["Glitch Wastes"].Center + Vector3.new(0, 10, 0)
	part.Anchored = true
	part.Color = Color3.fromRGB(50, 0, 50)
	part.Material = Enum.Material.Neon
	part.Parent = model
	
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = self.MaxHealth
	humanoid.Health = self.CurrentHealth
	humanoid.Parent = model
	
	model.Parent = workspace
	self.BossModel = model
	
	-- Notify Clients
	self.BossSpawned:FireAllClients({
		Name = bossData.Name,
		MaxHealth = self.MaxHealth,
		Model = model
	})
end

function BossService:Update(dt)
	if self.State ~= "Active" or not self.BossModel then return end
	
	-- Attack Logic
	if os.clock() >= self.NextAttackTime then
		self:PerformAttack()
	end
end

function BossService:PerformAttack()
	local bossData = Constants.BOSSES[self.BossId]
	local attack = bossData.Attacks.Spike -- Simple logic: just use Spike for now
	
	self.NextAttackTime = os.clock() + attack.Cooldown
	
	-- Telegraph
	self.BossAttack:FireAllClients("Spike", attack.Duration or 1)
	
	-- Deal Damage (Delayed)
	task.delay(1, function()
		if self.State ~= "Active" then return end
		if not self.BossModel or not self.BossModel.PrimaryPart then return end
		
		local origin = self.BossModel.PrimaryPart.Position
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char.PrimaryPart then
				local dist = (char.PrimaryPart.Position - origin).Magnitude
				if dist <= attack.Range then
					-- Deal damage via CombatService (if available) or direct humanoid
					local humanoid = char:FindFirstChild("Humanoid")
					if humanoid then
						humanoid:TakeDamage(attack.Damage)
					end
				end
			end
		end
	end)
end

function BossService:TakeDamage(amount)
	if self.State ~= "Active" then return end
	
	self.CurrentHealth = math.max(0, self.CurrentHealth - amount)
	
	-- Update Visuals
	if self.BossModel and self.BossModel:FindFirstChild("Humanoid") then
		self.BossModel.Humanoid.Health = self.CurrentHealth
	end
	
	self.BossUpdate:FireAllClients(self.CurrentHealth, self.MaxHealth)
	
	if self.CurrentHealth <= 0 then
		self:DefeatBoss()
	end
end

function BossService:DefeatBoss()
	self.State = "Defeated"
	print("[BossService] Boss Defeated!")
	
	self.BossDefeated:FireAllClients()
	
	-- Cleanup
	if self.BossModel then
		self.BossModel:Destroy()
		self.BossModel = nil
	end
	
	-- Respawn Timer
	task.delay(30, function()
		self:SpawnBoss(self.BossId)
	end)
end

return BossService
