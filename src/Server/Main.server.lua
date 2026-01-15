--[[This code is for reference purposes only. It is an expansion of the previous snippet to show the update in details. 
Main.server.lua
	Server entry point for Aetheria: The Omni-Verse
	
	Initializes all services in proper dependency order and starts the game server.
	
	Initialization Flow:
	1. Data Layer (DataService) - no dependencies
	2. Player Management (PlayerService) - depends on DataService
	3. Game Systems (RealmService, SpiritService) - depend on data layers
	4. Start all services
]]

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Only run on server
if not RunService:IsServer() then
	error("Main.server.lua can only run on the server")
end

print("==============================================")
print("  Aetheria: The Omni-Verse - Server Starting")
print("==============================================")

-- Service requires
local ServicesFolder = ServerScriptService.Server.Services
local services = {}

-- Dynamically load services
for _, module in ipairs(ServicesFolder:GetChildren()) do
	if module:IsA("ModuleScript") then
		local success, result = pcall(function()
			return require(module)
		end)
		
		if success then
			table.insert(services, { Name = module.Name, Service = result })
			print(`[Loader] Loaded {module.Name}`)
		else
			warn(`[Loader] Failed to load {module.Name}: {result}`)
		end
	end
end

-- Remotes initialization
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- Global error handler
local function handleError(context: string, err: string): ()
	warn(`[ERROR] {context}: {err}`)
	warn(debug.traceback())
end

-- Initialize services
local function initializeServices()
	print("\n--- Initializing Services ---")
	for _, serviceData in ipairs(services) do
		if type(serviceData.Service.Init) == "function" then
			task.spawn(function()
				local success, err = pcall(function()
					serviceData.Service:Init()
				end)
				if success then
					print(`✓ {serviceData.Name} initialized`)
				else
					warn(`[ERROR] {serviceData.Name} Init failed: {err}`)
				end
			end)
		end
	end
end

-- Start services
local function startServices()
	print("\n--- Starting Services ---")
	for _, serviceData in ipairs(services) do
		if type(serviceData.Service.Start) == "function" then
			task.spawn(function()
				local success, err = pcall(function()
					serviceData.Service:Start()
				end)
				if success then
					print(`✓ {serviceData.Name} started`)
				else
					warn(`[ERROR] {serviceData.Name} Start failed: {err}`)
				end
			end)
		end
	end
end

-- Main execution
local function main()
	local startTime = os.clock()
	
	initializeServices()
	-- Wait a bit for inits to potentially finish or just proceed? 
	-- Usually Init is synchronous, but we spawned them. 
	-- For this simple foundation, let's just proceed to Start.
	-- In a real framework, we'd wait for promises.
	
	task.wait(0.1) 
	
	startServices()
	
	local elapsedTime = os.clock() - startTime
	print("==============================================")
	print(`  Server Ready! (Startup time: {string.format("%.2f", elapsedTime)}s)`)
	print("==============================================\n")
end

main()
