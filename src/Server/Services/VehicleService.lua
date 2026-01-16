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

	-- Create a simple vehicle (VehicleSeat)
	local vehicle = Instance.new("VehicleSeat")
	vehicle.Name = vehicleData.Name
	vehicle.Size = Vector3.new(6, 1, 12)
	vehicle.Color = Color3.fromRGB(139, 69, 19) -- Wood
	vehicle.MaxSpeed = vehicleData.Speed
	vehicle.TurnSpeed = vehicleData.TurnSpeed
	vehicle.Position = rootPart.Position + (rootPart.CFrame.LookVector * 10) + Vector3.new(0, 2, 0)
	vehicle.Parent = Workspace

	-- Add a visual mesh or part to make it look like a boat?
	-- For now, just the seat is functional.
	
	-- Seat the player
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		vehicle:Sit(humanoid)
	end

	return true
end

return VehicleService
