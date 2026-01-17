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
	Remotes.GetEvent("OnCombatHit") -- Pre-create combat hit remote
	Remotes.GetEvent("CurrencyDrop") -- Pre-create currency drop remote
	
	attackRemote.OnServerEvent:Connect(function(player, target)
		self:HandleAttack(player, target)
	end)
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
		
		-- Notify client of currency drop
		local currencyRemote = Remotes.GetEvent("CurrencyDrop")
		currencyRemote:FireClient(player, currency, amount)
		print(string.format("[CombatService] %s received %d %s", player.Name, amount, currency))
	end
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
	local baseDamage = Constants.COMBAT.DAMAGE
	local bonus = 0
	
	local data = DataService.GetData(player)
	if data and data.Inventory then
		local equippedId = data.Inventory.EquippedSpirit
		if equippedId then
			local spirit = data.Inventory.Spirits[equippedId]
			if spirit and spirit.Stats then
				bonus = spirit.Stats.Atk or 0
			end
		end
	end
	
	-- 4. Critical Hit Check
	local isCritical, critMultiplier = self:CalculateCritical()
	local damage = math.floor((baseDamage + bonus) * critMultiplier)
	
	-- 5. Apply Damage
	humanoid:TakeDamage(damage)
	local hitPosition = rootPart.Position
	print(string.format("[CombatService] %s dealt %d damage%s to %s", player.Name, damage, isCritical and " (CRITICAL!)" or "", target.Name))
	
	-- 6. Fire OnCombatHit for visual feedback (minimal data)
	local combatHitRemote = Remotes.GetEvent("OnCombatHit")
	combatHitRemote:FireAllClients({
		damage = damage,
		isCritical = isCritical,
		hitPosition = hitPosition
	})
	
	-- 7. Replicate Damage Numbers
	local showDamageRemote = Remotes.GetEvent("ShowDamage")
	showDamageRemote:FireAllClients(rootPart, damage, isCritical)
	
	-- 8. Check for enemy death and drop currency
	if humanoid.Health <= 0 then
		local enemyName = target.Name
		self:DropCurrency(player, enemyName)
	end
end

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
	lastAttackTime[player.UserId] = nil
end)

return CombatService
