--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

local CombatService = {}
local lastAttackTime = {}

function CombatService:Init()
	print("[CombatService] Initializing...")
	
	local attackRemote = Remotes.GetEvent("Attack")
	
	attackRemote.OnServerEvent:Connect(function(player, target)
		self:HandleAttack(player, target)
	end)
end

function CombatService:Start()
	print("[CombatService] Starting...")
end

function CombatService:HandleAttack(player: Player, target: Instance?)
	if not target or not target:IsA("Model") then return end
	
	local humanoid = target:FindFirstChild("Humanoid")
	local rootPart = target:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart then return end
	
	-- 1. Cooldown Check
	local now = os.clock()
	local lastTime = lastAttackTime[player.UserId] or 0
	
	if now - lastTime < Constants.COMBAT.COOLDOWN then
		return -- Cooldown active
	end
	
	lastAttackTime[player.UserId] = now
	
	-- 2. Distance Check
	local character = player.Character
	if not character or not character.PrimaryPart then return end
	
	local distance = (character.PrimaryPart.Position - rootPart.Position).Magnitude
	if distance > Constants.COMBAT.MAX_DISTANCE then
		return -- Too far
	end
	
	-- 3. Apply Damage
	humanoid:TakeDamage(Constants.COMBAT.DAMAGE)
	print(string.format("[CombatService] %s dealt %d damage to %s", player.Name, Constants.COMBAT.DAMAGE, target.Name))
	
	-- 4. Replicate Visuals
	local showDamageRemote = Remotes.GetEvent("ShowDamage")
	-- Fire to all clients so everyone sees the damage number
	showDamageRemote:FireAllClients(rootPart, Constants.COMBAT.DAMAGE, false) -- false for IsCritical (placeholder)
end

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
	lastAttackTime[player.UserId] = nil
end)

return CombatService
