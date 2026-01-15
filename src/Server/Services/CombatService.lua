--!strict
--[[
	CombatService.lua
	Server-authoritative combat system. Validates attacks, processes damage, and replicates to clients.
	
	Features:
	- Attack validation with rate limiting
	- Damage calculation with Spirit stats
	- Hit detection and confirmation
	- Critical hit system
	- Damage replication to clients
]]

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Only run on server
if not RunService:IsServer() then
	error("CombatService can only be required on the server")
end

-- Services
local PlayerService = require(ServerScriptService.Server.Services.PlayerService)
local SpiritService = require(ServerScriptService.Server.Services.SpiritService)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- Service
local CombatService = {
	_attackCooldowns = {} :: { [number]: number }, -- userId -> last attack time
}

-- Rate limiting check
local function checkRateLimit(player: Player): boolean
	local userId = player.UserId
	local lastAttack = CombatService._attackCooldowns[userId] or 0
	local cooldown = 1 / Constants.Combat.AttackRateLimit
	
	if (os.clock() - lastAttack) < cooldown then
		return false
	end
	
	return true
end

-- Validate attack range
local function validateRange(attacker: Player, targetPosition: Vector3): boolean
	local character = attacker.Character
	if not character then
		return false
	end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end
	
	local distance = (rootPart.Position - targetPosition).Magnitude
	return distance <= Constants.Combat.MaxAttackRange
end

-- Calculate damage
local function calculateDamage(attackerSpirits: any, baseAttack: number): (number, boolean)
	local totalAttack = baseAttack
	
	-- Add Spirit attack stats
	for _, spirit in attackerSpirits do
		totalAttack += spirit.Stats.Attack
	end
	
	-- Calculate critical hit
	local critChance = Constants.Combat.BaseCritChance
	local isCritical = math.random() < critChance
	
	local damage = totalAttack * (isCritical and Constants.Combat.CritDamageMultiplier or 1)
	
	return damage, isCritical
end

-- Find target at position
local function findTargetAtPosition(attacker: Player, targetPosition: Vector3): Model?
	local workspace = game:GetService("Workspace")
	
	-- Raycast from attacker to target position
	local character = attacker.Character
	if not character then
		return nil
	end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return nil
	end
	
	local direction = (targetPosition - rootPart.Position).Unit
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = workspace:Raycast(rootPart.Position, direction * Constants.Combat.MaxAttackRange, raycastParams)
	
	if result and result.Instance then
		-- Find model (character or NPC)
		local target = result.Instance:FindFirstAncestorOfClass("Model")
		if target and target:FindFirstChild("Humanoid") then
			return target
		end
	end
	
	return nil
end

-- Process attack
function CombatService:ProcessAttack(player: Player, targetPosition: Vector3): ()
	-- 1. Rate limiting
	if not checkRateLimit(player) then
		warn(`{player.Name} is attacking too fast`)
		return
	end
	
	-- 2. Validate range
	if not validateRange(player, targetPosition) then
		warn(`{player.Name} attack out of range`)
		return
	end
	
	-- 3. Check if player is alive
	if not PlayerService:IsPlayerAlive(player) then
		return
	end
	
	-- 4. Get equipped spirits
	local equippedSpirits = SpiritService:GetEquippedSpirits(player)
	if #equippedSpirits == 0 then
		warn(`{player.Name} has no equipped spirits`)
		return
	end
	
	-- 5. Find target
	local target = findTargetAtPosition(player, targetPosition)
	if not target then
		-- No target, still confirm hit for feedback
		local hitConfirmedRemote = Remotes.GetRemote("Combat", "HitConfirmed")
		if hitConfirmedRemote then
			hitConfirmedRemote:FireClient(player, targetPosition)
		end
		return
	end
	
	-- 6. Calculate damage
	local damage, isCritical = calculateDamage(equippedSpirits, 10) -- Base 10 damage
	
	-- 7. Apply damage
	local humanoid = target:FindFirstChild("Humanoid") :: Humanoid?
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(damage)
		
		-- 8. Send hit confirmation
		local hitConfirmedRemote = Remotes.GetRemote("Combat", "HitConfirmed")
		if hitConfirmedRemote then
			hitConfirmedRemote:FireClient(player, targetPosition)
		end
		
		-- 9. Send damage number to all nearby players
		local damageNumberRemote = Remotes.GetRemote("Combat", "DamageNumber")
		if damageNumberRemote then
			local damagePosition = target:FindFirstChild("Head") and target.Head.Position or target:GetPivot().Position
			damagePosition = damagePosition + Vector3.new(0, 3, 0)
			
			-- Send to attacker
			damageNumberRemote:FireClient(player, damagePosition, damage, isCritical)
			
			-- Send to nearby players
			for _, nearbyPlayer in game:GetService("Players"):GetPlayers() do
				if nearbyPlayer ~= player and nearbyPlayer.Character then
					local nearbyRoot = nearbyPlayer.Character:FindFirstChild("HumanoidRootPart")
					if nearbyRoot and (nearbyRoot.Position - damagePosition).Magnitude < 100 then
						damageNumberRemote:FireClient(nearbyPlayer, damagePosition, damage, isCritical)
					end
				end
			end
		end
		
		print(`{player.Name} dealt {damage} damage to {target.Name} (Critical: {isCritical})`)
		
		-- Award experience to spirits
		for _, spirit in equippedSpirits do
			SpiritService:AddExperience(player, spirit.Id, 5)
		end
	end
	
	-- Update cooldown
	CombatService._attackCooldowns[player.UserId] = os.clock()
end

-- Initialize service
function CombatService:Init(): ()
	print("Initializing CombatService...")
	print("CombatService initialized")
end

-- Start service
function CombatService:Start(): ()
	print("Starting CombatService...")
	
	-- Setup remote event listeners
	local requestAttackRemote = Remotes.GetRemote("Combat", "RequestAttack")
	if requestAttackRemote then
		requestAttackRemote.OnServerEvent:Connect(function(player: Player, targetPosition: Vector3)
			-- Validate input type
			if typeof(targetPosition) ~= "Vector3" then
				warn(`Invalid targetPosition from {player.Name}`)
				return
			end
			
			-- Check for NaN
			if targetPosition.X ~= targetPosition.X then
				warn(`NaN detected in targetPosition from {player.Name}`)
				return
			end
			
			-- Process attack
			CombatService:ProcessAttack(player, targetPosition)
		end)
	end
	
	-- Cleanup on player leave
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		CombatService._attackCooldowns[player.UserId] = nil
	end)
	
	print("CombatService started")
end

return CombatService
