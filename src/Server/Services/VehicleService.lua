local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

local VehicleService = {}

function VehicleService:Init()
	print("[VehicleService] Init")
	self.SpawnVehicleEvent = Remotes.GetEvent("SpawnVehicle")
	
	self.SpawnVehicleEvent.OnServerEvent:Connect(function(player, vehicleId)
		self:SpawnVehicle(player, vehicleId)
	end)
end

function VehicleService:Start()
	print("[VehicleService] Start")
end

function VehicleService:SpawnVehicle(player, vehicleId)
	local vehicleData = Constants.VEHICLES[vehicleId]
	if not vehicleData then
		warn("Invalid vehicle ID: " .. tostring(vehicleId))
		return false
	end

	local character = player.Character
	if not character then return false end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- Create Model
	local model = Instance.new("Model")
	model.Name = vehicleData.Name .. "_" .. player.Name
	
	-- Hull
	local hull = Instance.new("Part")
	hull.Name = "Hull"
	hull.Size = Vector3.new(6, 1, 12)
	hull.Color = Color3.fromRGB(139, 69, 19) -- Brown Wood
	hull.Material = Enum.Material.Wood
	hull.Anchored = false
	hull.CanCollide = true
	hull.Parent = model
	
	-- VehicleSeat
	local seat = Instance.new("VehicleSeat")
	seat.Name = "VehicleSeat"
	seat.Size = Vector3.new(2, 1, 2)
	seat.Color = Color3.fromRGB(100, 100, 100)
	seat.MaxSpeed = vehicleData.Speed
	seat.TurnSpeed = vehicleData.TurnSpeed
	seat.Position = hull.Position + Vector3.new(0, 0.5, 0)
	seat.Parent = model
	
	-- Weld Seat to Hull
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hull
	weld.Part1 = seat
	weld.Parent = hull
	
	-- Position near player
	local spawnPos = rootPart.Position + (rootPart.CFrame.LookVector * 10) + Vector3.new(0, 2, 0)
	model:PivotTo(CFrame.new(spawnPos))
	
	model.Parent = Workspace
	
	-- Sit the player
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		seat:Sit(humanoid)
	end

	return true
end

return VehicleService
