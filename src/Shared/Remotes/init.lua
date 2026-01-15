--!strict
--[[
	Remotes/init.lua
	Centralized Remote Event creation and management for client-server communication.
	
	Creates all necessary RemoteEvents and RemoteFunctions in Replicated Storage.
	This runs on the server during initialization to ensure all remotes exist
	before clients try to reference them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

-- Remote definitions: creates RemoteEvents/RemoteFunctions organized by category
local REMOTE_DEFINITIONS = {
	Combat = {
		{ Name = "RequestAttack", Type = "Event" },
		{ Name = "HitConfirmed", Type = "Event" },
		{ Name = "AbilityCast", Type = "Event" },
		{ Name = "DamageNumber", Type = "Event" },
	},
	Data = {
		{ Name = "DataChanged", Type = "Event" },
		{ Name = "ReplicateData", Type = "Event" },
		{ Name = "RequestData", Type = "Function" },
	},
	Realm = {
		{ Name = "TeleportToRealm", Type = "Event" },
		{ Name = "PlaceFurniture", Type = "Event" },
		{ Name = "RemoveFurniture", Type = "Event" },
		{ Name = "StartParty", Type = "Event" },
	},
	Spirit = {
		{ Name = "EquipSpirit", Type = "Event" },
		{ Name = "UnequipSpirit", Type = "Event" },
		{ Name = "BreedSpirits", Type = "Event" },
		{ Name = "RequestSpiritData", Type = "Function" },
	},
	Economy = {
		{ Name = "PurchaseItem", Type = "Event" },
		{ Name = "ListOnMarketplace", Type = "Event" },
		{ Name = "BuyFromMarketplace", Type = "Event" },
	},
}

-- Initialize all remotes (SERVER ONLY)
function Remotes.InitializeRemotes(): ()
	if not RunService:IsServer() then
		error("InitializeRemotes can only be called on the server!")
	end
	
	print("Initializing Remote Events...")
	
	-- Create Remotes folder in ReplicatedStorage
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end
	
	-- Create all remotes by category
	for category, remotes in REMOTE_DEFINITIONS do
		local categoryFolder = remotesFolder:FindFirstChild(category)
		if not categoryFolder then
			categoryFolder = Instance.new("Folder")
			categoryFolder.Name = category
			categoryFolder.Parent = remotesFolder
		end
		
		for _, remoteInfo in remotes do
			local existing = categoryFolder:FindFirstChild(remoteInfo.Name)
			if not existing then
				local remote: Instance
				if remoteInfo.Type == "Event" then
					remote = Instance.new("RemoteEvent")
				else
					remote = Instance.new("RemoteFunction")
				end
				
				remote.Name = remoteInfo.Name
				remote.Parent = categoryFolder
				print(`  Created {remoteInfo.Type}: {category}/{remoteInfo.Name}`)
			end
		end
	end
	
	print("✓ All Remote Events created")
end

-- Get remote references (CLIENT SAFE)
function Remotes.WaitForRemotes(timeout: number?): boolean
	local timeoutDuration = timeout or 10
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", timeoutDuration)
	
	if not remotesFolder then
		warn("Failed to find Remotes folder in ReplicatedStorage")
		return false
	end
	
	-- Wait for all categories
	for category, _ in REMOTE_DEFINITIONS do
		local categoryFolder = remotesFolder:WaitForChild(category, timeoutDuration)
		if not categoryFolder then
			warn(`Failed to find category folder: {category}`)
			return false
		end
	end
	
	return true
end

-- Get a specific remote
function Remotes.GetRemote(category: string, remoteName: string): RemoteEvent | RemoteFunction | nil
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotesFolder then
		return nil
	end
	
	local categoryFolder = remotesFolder:FindFirstChild(category)
	if not categoryFolder then
		return nil
	end
	
	return categoryFolder:FindFirstChild(remoteName) :: (RemoteEvent | RemoteFunction)?
end

return Remotes
