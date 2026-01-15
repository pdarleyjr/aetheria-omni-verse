local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IS_SERVER = RunService:IsServer()

local Remotes = {}
local cache = {}

-- Folder to store remotes
local remoteFolder

if IS_SERVER then
	-- Check if it already exists (in case of reload or pre-created)
	remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "Remotes"
		remoteFolder.Parent = ReplicatedStorage
	end
else
	remoteFolder = ReplicatedStorage:WaitForChild("Remotes")
end

-- Helper to get or create remote
local function getRemote(name, class)
	if cache[name] then
		return cache[name]
	end

	if IS_SERVER then
		local remote = remoteFolder:FindFirstChild(name)
		if not remote then
			remote = Instance.new(class)
			remote.Name = name
			remote.Parent = remoteFolder
		end
		cache[name] = remote
		return remote
	else
		local remote = remoteFolder:WaitForChild(name)
		cache[name] = remote
		return remote
	end
end

function Remotes.GetEvent(name)
	return getRemote(name, "RemoteEvent")
end

function Remotes.GetFunction(name)
	return getRemote(name, "RemoteFunction")
end

return Remotes
