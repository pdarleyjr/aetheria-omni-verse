--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local DataService = require(script.Parent.DataService)

local CombatService = {}
local lastAttackTime = {}

function CombatService:Init()
	print("[CombatService] Initializing...")
	
	local attackRemote = Remotes.GetEvent("RequestAttack")
	Remotes.GetEvent("ShowDamage") -- Pre-create to prevent client infinite yield
	
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
	
	-- 3. Calculate Damage (Base + Spirit)
	local damage = Constants.COMBAT.DAMAGE
	local bonus = 0
	
	local data = DataService.GetData(player)
	if data and data.Inventory then
		local equippedId = data.Inventory.EquippedSpirit
		if equippedId then
			local spirit = data.Inventory.Spirits[equippedId]
			if spirit and spirit.Stats then
				-- Damage Formula: Base + Spirit Attack
				bonus = spirit.Stats.Atk or 0
				damage = damage + bonus
			end
		end
	end
	
	-- 4. Apply Damage
	humanoid:TakeDamage(damage)
	print(string.format("[CombatService] %s dealt %d damage (%d Base + %d Bonus) to %s", player.Name, damage, Constants.COMBAT.DAMAGE, bonus, target.Name))
	
	-- 5. Replicate Visuals
	local showDamageRemote = Remotes.GetEvent("ShowDamage")
	showDamageRemote:FireAllClients(rootPart, damage, false) -- false for IsCritical (placeholder)
end

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
	lastAttackTime[player.UserId] = nil
end)

return CombatService
