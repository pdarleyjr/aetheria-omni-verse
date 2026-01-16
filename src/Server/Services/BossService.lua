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
	
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)
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

function BossService:OnPlayerAdded(player)
	if self.State == "Active" and self.BossModel then
		local bossData = Constants.BOSSES[self.BossId]
		if bossData then
			self.BossSpawned:FireClient(player, {
				Name = bossData.Name,
				MaxHealth = self.MaxHealth,
				Model = self.BossModel
			})
			self.BossUpdate:FireClient(player, self.CurrentHealth, self.MaxHealth)
		end
	end
end

function BossService:SpawnBoss(bossId)
	local bossData = Constants.BOSSES[bossId]
	if not bossData then return end
	
	print("[BossService] Spawning " .. bossData.Name)
	
	self.MaxHealth = bossData.Health
	self.CurrentHealth = self.MaxHealth
	self.State = "Active"
	self.BossId = bossId
	
	-- Create Model
	local model = Instance.new("Model")
	model.Name = bossData.Name
	
	local assetId = Constants.ASSETS.BOSSES[bossId]
	local rootPart
	
	if assetId and assetId ~= "rbxassetid://0" and assetId ~= "" then
		-- Real asset logic
	else
		-- Procedural Boss: The Glitch King
		-- A large, imposing figure made of dark, glitchy blocks
		
		rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(15, 30, 15) -- Scaled up
		rootPart.Position = Constants.ZONES["Glitch Wastes"].Center + Vector3.new(0, 15, 0)
		rootPart.Anchored = true
		rootPart.Color = Color3.fromRGB(20, 0, 20)
		rootPart.Material = Enum.Material.Neon
		rootPart.Parent = model
		
		-- Add a "Crown"
		local crown = Instance.new("Part")
		crown.Name = "Crown"
		crown.Size = Vector3.new(18, 6, 18) -- Scaled up
		crown.Color = Color3.fromRGB(255, 0, 0) -- Corrupted red
		crown.Material = Enum.Material.Neon
		crown.CanCollide = false
		crown.Parent = model
		
		local weld = Instance.new("Weld")
		weld.Part0 = rootPart
		weld.Part1 = crown
		weld.C0 = CFrame.new(0, 18, 0)
		weld.Parent = crown
		
		-- Add "Floating" segments
		for i = 1, 4 do
			local segment = Instance.new("Part")
			segment.Size = Vector3.new(6, 12, 6) -- Scaled up
			segment.Color = Color3.fromRGB(50, 0, 50)
			segment.Material = Enum.Material.ForceField
			segment.CanCollide = false
			segment.Parent = model
			
			local angle = math.rad(i * 90)
			local offset = Vector3.new(math.cos(angle) * 15, 0, math.sin(angle) * 15)
			
			local sWeld = Instance.new("Weld")
			sWeld.Part0 = rootPart
			sWeld.Part1 = segment
			sWeld.C0 = CFrame.new(offset)
			sWeld.Parent = segment
		end
	end
	
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = self.MaxHealth
	humanoid.Health = self.CurrentHealth
	humanoid.Parent = model
	
	-- Add Overhead Billboard
	local bg = Instance.new("BillboardGui")
	bg.Name = "BossInfo"
	bg.Adornee = rootPart
	bg.Size = UDim2.new(10, 0, 2, 0)
	bg.StudsOffset = Vector3.new(0, 25, 0)
	bg.AlwaysOnTop = true
	bg.Parent = rootPart
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = bossData.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.Creepster
	nameLabel.Parent = bg
	
	model.PrimaryPart = rootPart
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
