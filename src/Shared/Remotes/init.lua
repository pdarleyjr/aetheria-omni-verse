local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

function Remotes.Init()
	print("--- Initializing Remote Events ---")
	
	local function createRemote(name, type)
		local folder = ReplicatedStorage:FindFirstChild("Remotes")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			folder.Parent = ReplicatedStorage
		end
		
		local path = string.split(name, "/")
		local current = folder
		
		for i = 1, #path - 1 do
			local sub = current:FindFirstChild(path[i])
			if not sub then
				sub = Instance.new("Folder")
				sub.Name = path[i]
				sub.Parent = current
			end
			current = sub
		end
		
		local remoteName = path[#path]
		local remote = current:FindFirstChild(remoteName)
		
		if not remote then
			remote = Instance.new(type)
			remote.Name = remoteName
			remote.Parent = current
			print("  Created Event: " .. name)
		end
		
		return remote
	end

	-- Combat Remotes
	createRemote("Combat/RequestAttack", "RemoteEvent")
	createRemote("Combat/HitConfirmed", "RemoteEvent")
	createRemote("Combat/AbilityCast", "RemoteEvent")
	
	-- Data Remotes
	createRemote("Data/DataChanged", "RemoteEvent")
	createRemote("Data/GetData", "RemoteFunction")
	
	-- Realm Remotes
	createRemote("Realm/PlaceFurniture", "RemoteFunction")
	createRemote("Realm/TeleportToRealm", "RemoteFunction")
	
	-- Boss Remotes
	createRemote("Boss/BossSpawned", "RemoteEvent")
	createRemote("Boss/BossUpdate", "RemoteEvent")
	createRemote("Boss/BossAttack", "RemoteEvent")
	createRemote("Boss/BossDefeated", "RemoteEvent")
	
	print("✓ All Remote Events created")
end

return Remotes
