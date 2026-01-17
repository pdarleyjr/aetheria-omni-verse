local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}
local _events = {}
local _functions = {}

function Remotes.Init()
	print("--- Initializing Remote Events ---")
	
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	
	local function createRemote(name, type)
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new(type)
			remote.Name = name
			remote.Parent = folder
			print("  Created " .. type .. ": " .. name)
		end
		return remote
	end

	-- Combat Remotes
	_events["RequestAttack"] = createRemote("RequestAttack", "RemoteEvent")
	_events["HitConfirmed"] = createRemote("HitConfirmed", "RemoteEvent")
	_events["AbilityCast"] = createRemote("AbilityCast", "RemoteEvent")
	_events["AbilityUsed"] = createRemote("AbilityUsed", "RemoteEvent")
	_events["ShowDamage"] = createRemote("ShowDamage", "RemoteEvent")
	_events["OnCombatHit"] = createRemote("OnCombatHit", "RemoteEvent")
	_events["OnEnemyDeath"] = createRemote("OnEnemyDeath", "RemoteEvent")
	_events["CurrencyDrop"] = createRemote("CurrencyDrop", "RemoteEvent")
	_events["RequestSkill"] = createRemote("RequestSkill", "RemoteEvent")
	
	-- Data Remotes
	_events["DataChanged"] = createRemote("DataChanged", "RemoteEvent")
	_events["UpdateHUD"] = createRemote("UpdateHUD", "RemoteEvent")
	_functions["GetData"] = createRemote("GetData", "RemoteFunction")
	
	-- Realm Remotes
	_functions["PlaceFurniture"] = createRemote("PlaceFurniture", "RemoteFunction")
	_functions["TeleportToRealm"] = createRemote("TeleportToRealm", "RemoteFunction")
	_events["TeleportToHub"] = createRemote("TeleportToHub", "RemoteEvent")
	
	-- Spirit Remotes
	_events["EquipSpirit"] = createRemote("EquipSpirit", "RemoteEvent")
	
	-- Progression Remotes
	_events["LevelUp"] = createRemote("LevelUp", "RemoteEvent")
	
	-- Boss Remotes
	_events["BossSpawned"] = createRemote("BossSpawned", "RemoteEvent")
	_events["BossUpdate"] = createRemote("BossUpdate", "RemoteEvent")
	_events["BossAttack"] = createRemote("BossAttack", "RemoteEvent")
	_events["BossDefeated"] = createRemote("BossDefeated", "RemoteEvent")
	_events["BossUniqueId"] = createRemote("BossUniqueId", "RemoteEvent")
	
	-- Enemy Remotes
	_events["EnemyTelegraph"] = createRemote("EnemyTelegraph", "RemoteEvent")
	
	-- Quest Remotes
	_events["QuestUpdate"] = createRemote("QuestUpdate", "RemoteEvent")
	_functions["AcceptQuest"] = createRemote("AcceptQuest", "RemoteFunction")
	_functions["CompleteQuest"] = createRemote("CompleteQuest", "RemoteFunction")
	
	-- Vehicle Remotes
	_events["SpawnVehicle"] = createRemote("SpawnVehicle", "RemoteEvent")
	
	-- Fishing Remotes
	_events["CastLine"] = createRemote("CastLine", "RemoteEvent")
	_events["CatchFish"] = createRemote("CatchFish", "RemoteEvent")
	
	-- Trade Remotes
	_events["TradeEvent"] = createRemote("TradeEvent", "RemoteEvent")
	_functions["RequestTrade"] = createRemote("RequestTrade", "RemoteFunction")
	_functions["TradeFunction"] = createRemote("TradeFunction", "RemoteFunction")
	
	-- LiveOps Remotes
	_events["Announcement"] = createRemote("Announcement", "RemoteEvent")
	
	-- Breeding Remotes
	_functions["BreedSpirits"] = createRemote("BreedSpirits", "RemoteFunction")
	
	-- Shop/Economy Remotes
	_functions["PurchaseItem"] = createRemote("PurchaseItem", "RemoteFunction")
	_events["GoldUpdate"] = createRemote("GoldUpdate", "RemoteEvent")
	_events["PurchaseResult"] = createRemote("PurchaseResult", "RemoteEvent")
	
	-- Enemy Remotes (additional)
	_events["EnemyDeath"] = createRemote("EnemyDeath", "RemoteEvent")
	
	print("✓ All Remote Events created")
end

function Remotes.GetEvent(name)
	if _events[name] then return _events[name] end
	
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	local remote = folder:WaitForChild(name)
	if remote:IsA("RemoteEvent") then
		_events[name] = remote
		return remote
	end
	error("RemoteEvent not found: " .. name)
end

function Remotes.GetFunction(name)
	if _functions[name] then return _functions[name] end
	
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	local remote = folder:WaitForChild(name)
	if remote:IsA("RemoteFunction") then
		_functions[name] = remote
		return remote
	end
	error("RemoteFunction not found: " .. name)
end

return Remotes
