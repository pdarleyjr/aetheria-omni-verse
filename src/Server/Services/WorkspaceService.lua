local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

local WorkspaceService = {}

function WorkspaceService:Init()
	print("[WorkspaceService] Initializing...")
end

function WorkspaceService:Start()
	print("[WorkspaceService] Starting...")
	self:GenerateGlitchSpikes()
end

function WorkspaceService:GenerateGlitchSpikes()
	local zone = Constants.ZONES["Glitch Wastes"]
	if not zone then return end
	
	local spikesFolder = Instance.new("Folder")
	spikesFolder.Name = "GlitchSpikes"
	spikesFolder.Parent = Workspace
	
	local center = zone.Center
	local size = zone.Size
	
	-- Generate 20 random spikes
	for i = 1, 20 do
		local spike = Instance.new("Part")
		spike.Name = "GlitchSpike"
		spike.Size = Vector3.new(4, 12, 4)
		spike.Anchored = true
		spike.CanCollide = false
		spike.Color = Color3.fromRGB(255, 0, 0)
		spike.Material = Enum.Material.Neon
		spike.Shape = Enum.PartType.Cylinder
		
		-- Random position within zone
		local x = center.X + math.random(-size.X/2, size.X/2)
		local z = center.Z + math.random(-size.Z/2, size.Z/2)
		spike.Position = Vector3.new(x, center.Y, z)
		
		-- Rotate to look like a spike coming out of ground
		spike.CFrame = CFrame.new(spike.Position) * CFrame.Angles(0, 0, math.rad(90))
		
		spike.Parent = spikesFolder
		
		-- Damage logic
		local debounce = {}
		spike.Touched:Connect(function(hit)
			local char = hit.Parent
			local humanoid = char:FindFirstChild("Humanoid")
			if humanoid and not debounce[char] then
				debounce[char] = true
				humanoid:TakeDamage(15)
				
				-- Visual feedback
				local highlight = Instance.new("Highlight")
				highlight.FillColor = Color3.fromRGB(255, 0, 0)
				highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				highlight.Parent = char
				task.delay(0.2, function() highlight:Destroy() end)
				
				task.delay(1, function()
					debounce[char] = nil
				end)
			end
		end)
	end
	
	print("[WorkspaceService] Generated Glitch Spikes")
end

return WorkspaceService
