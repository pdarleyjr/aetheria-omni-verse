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
