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
	_events["ShowDamage"] = createRemote("ShowDamage", "RemoteEvent")
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
	
	-- Boss Remotes
	_events["BossSpawned"] = createRemote("BossSpawned", "RemoteEvent")
	_events["BossUpdate"] = createRemote("BossUpdate", "RemoteEvent")
	_events["BossAttack"] = createRemote("BossAttack", "RemoteEvent")
	_events["BossDefeated"] = createRemote("BossDefeated", "RemoteEvent")
	_events["BossUniqueId"] = createRemote("BossUniqueId", "RemoteEvent")
	
	-- Quest Remotes
	_events["QuestUpdate"] = createRemote("QuestUpdate", "RemoteEvent")
	_functions["AcceptQuest"] = createRemote("AcceptQuest", "RemoteFunction")
	_functions["CompleteQuest"] = createRemote("CompleteQuest", "RemoteFunction")
	
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
