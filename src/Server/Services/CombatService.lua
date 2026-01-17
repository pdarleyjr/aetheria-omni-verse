--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Maid = require(ReplicatedStorage.Shared.Modules.Maid)
local DataService = require(script.Parent.DataService)

local CombatService = {}
local maid = Maid.new()
local lastAttackTime = {}

function CombatService:Init()
	print("[CombatService] Initializing...")
	
	local attackRemote = Remotes.GetEvent("RequestAttack")
	Remotes.GetEvent("ShowDamage") -- Pre-create to prevent client infinite yield
	Remotes.GetEvent("OnCombatHit") -- Pre-create combat hit remote
	Remotes.GetEvent("CurrencyDrop") -- Pre-create currency drop remote
	Remotes.GetEvent("EnemyDeath") -- Pre-create enemy death remote for visual/audio feedback
	Remotes.GetEvent("AbilityUsed") -- Pre-create ability usage remote
	
	maid:GiveTask(attackRemote.OnServerEvent:Connect(function(player, target, damageType)
		self:HandleAttack(player, target, damageType)
	end))
end

function CombatService:Start()
	print("[CombatService] Starting...")
end

function CombatService:CalculateCritical()
	local isCritical = math.random() < Constants.COMBAT.CRITICAL_CHANCE
	local multiplier = isCritical and Constants.COMBAT.CRITICAL_MULTIPLIER or 1
	return isCritical, multiplier
end

function CombatService:DropCurrency(player: Player, enemyName: string)
	local dropRates = Constants.CURRENCY_DROP_RATES[enemyName] or Constants.CURRENCY_DROP_RATES.Default
	local data = DataService.GetData(player)
	if not data or not data.Currency then return end
	
	for currency, range in pairs(dropRates) do
		local amount = math.random(range.Min, range.Max)
		data.Currency[currency] = (data.Currency[currency] or 0) + amount
		
		local currencyRemote = Remotes.GetEvent("CurrencyDrop")
		currencyRemote:FireClient(player, currency, amount)
		print(string.format("[CombatService] %s received %d %s", player.Name, amount, currency))
	end
end

function CombatService:HandleAttack(player: Player, target: Instance?, damageType: string?)
	if not target or not target:IsA("Model") then return end
	
	local humanoid = target:FindFirstChild("Humanoid")
	local rootPart = target:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart then return end
	
	-- 1. Cooldown Check
	local now = os.clock()
	local lastTime = lastAttackTime[player.UserId] or 0
	
	if now - lastTime < Constants.COMBAT.COOLDOWN then
		return
	end
	
	lastAttackTime[player.UserId] = now
	
	-- 2. Distance Check
	local character = player.Character
	if not character or not character.PrimaryPart then return end
	
	local distance = (character.PrimaryPart.Position - rootPart.Position).Magnitude
	if distance > Constants.COMBAT.MAX_DISTANCE then
		return
	end
	
	-- 3. Calculate Damage (Base + Spirit)
	local baseDamage = Constants.COMBAT.DAMAGE
	local bonus = 0
	local effectiveDamageType = damageType or "Physical"
	
	local data = DataService.GetData(player)
	if data and data.Inventory then
		local equippedId = data.Inventory.EquippedSpirit
		if equippedId then
			local spirit = data.Inventory.Spirits[equippedId]
			if spirit and spirit.Stats then
				bonus = spirit.Stats.Atk or 0
			end
			-- Use spirit's element type if no damage type specified
			if spirit and spirit.Type and not damageType then
				effectiveDamageType = spirit.Type
			end
		end
	end
	
	-- 4. Critical Hit Check
	local isCritical, critMultiplier = self:CalculateCritical()
	local damage = math.floor((baseDamage + bonus) * critMultiplier)
	
	-- 5. Apply Damage
	local wasAlive = humanoid.Health > 0
	humanoid:TakeDamage(damage)
	local hitPosition = rootPart.Position
	local isDead = humanoid.Health <= 0
	print(string.format("[CombatService] %s dealt %d %s damage%s to %s", player.Name, damage, effectiveDamageType, isCritical and " (CRITICAL!)" or "", target.Name))
	
	-- 6. Fire OnCombatHit for visual/audio feedback
	local combatHitRemote = Remotes.GetEvent("OnCombatHit")
	combatHitRemote:FireAllClients({
		damage = damage,
		isCritical = isCritical,
		hitPosition = hitPosition,
		damageType = effectiveDamageType,
	})
	
	-- 7. Replicate Damage Numbers
	local showDamageRemote = Remotes.GetEvent("ShowDamage")
	showDamageRemote:FireAllClients(rootPart, damage, isCritical, effectiveDamageType)
	
	-- 8. Check for enemy death
	if wasAlive and isDead then
		local enemyName = target.Name
		
		-- Fire EnemyDeath event for death burst effects
		local deathRemote = Remotes.GetEvent("EnemyDeath")
		deathRemote:FireAllClients(hitPosition, effectiveDamageType)
		
		-- Drop currency
		self:DropCurrency(player, enemyName)
	end
end

-- Cleanup on player leaving
maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
	lastAttackTime[player.UserId] = nil
end))

return CombatService
