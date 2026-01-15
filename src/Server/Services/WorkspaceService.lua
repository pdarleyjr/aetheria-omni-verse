--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local WorkspaceService = {}

function WorkspaceService:Init()
	print("[WorkspaceService] Initializing...")
	self:EnsureHubExists()
end

function WorkspaceService:Start()
	print("[WorkspaceService] Starting...")
	self:SpawnDummy()
end

function WorkspaceService:SpawnDummy()
	local hub = Workspace:FindFirstChild("Hub")
	if not hub then return end

	if hub:FindFirstChild("TrainingDummy") then return end

	local dummy = Instance.new("Model")
	dummy.Name = "TrainingDummy"
	
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Always
	humanoid.Parent = dummy
	
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(4, 5, 1)
	rootPart.Position = Vector3.new(10, 55, 0) -- Near spawn
	rootPart.Anchored = true
	rootPart.CanCollide = true
	rootPart.Color = Color3.fromRGB(200, 50, 50)
	rootPart.Parent = dummy
	
	dummy.PrimaryPart = rootPart
	dummy.Parent = hub
	
	print("[WorkspaceService] Spawning Training Dummy")
end

function WorkspaceService:EnsureHubExists()
	local hub = Workspace:FindFirstChild("Hub")
	if not hub then
		hub = Instance.new("Folder")
		hub.Name = "Hub"
		hub.Parent = Workspace
		print("[WorkspaceService] Created Hub folder")
	end
	
	local spawnLocation = hub:FindFirstChild("SpawnLocation")
	if not spawnLocation then
		spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Name = "SpawnLocation"
		spawnLocation.Size = Vector3.new(200, 5, 200) -- Large platform
		spawnLocation.Position = Vector3.new(0, 50, 0) -- Height 50
		spawnLocation.Anchored = true
		spawnLocation.CanCollide = true
		spawnLocation.Material = Enum.Material.Neon
		spawnLocation.Color = Color3.fromRGB(255, 255, 255)
		spawnLocation.Parent = hub
		print("[WorkspaceService] Created Hub SpawnLocation")
	end
end

function WorkspaceService:TeleportToHub(player: Player)
	local hub = Workspace:FindFirstChild("Hub")
	if not hub then return end
	
	local spawnLocation = hub:FindFirstChild("SpawnLocation")
	if not spawnLocation or not spawnLocation:IsA("BasePart") then return end
	
	if player.Character and player.Character.PrimaryPart then
		local targetCFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
		
		-- Streaming Safety
		player:RequestStreamAroundAsync(targetCFrame.Position)
		
		local rootPart = player.Character.PrimaryPart
		if rootPart then
			rootPart.Anchored = true
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
			
			player.Character:PivotTo(targetCFrame)
			
			task.delay(1, function()
				if rootPart and rootPart.Parent then
					rootPart.Anchored = false
				end
			end)
		end
	end
end

return WorkspaceService
