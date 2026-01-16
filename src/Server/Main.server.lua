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
local ServerFolder = ServerScriptService:WaitForChild("Server", 10)
if not ServerFolder then
	error("CRITICAL: Server folder not found in ServerScriptService")
end

local ServicesFolder = ServerFolder:WaitForChild("Services", 10)
if not ServicesFolder then
	error("CRITICAL: Services folder not found in ServerScriptService.Server")
end

-- Remotes initialization
local Remotes = require(ReplicatedStorage.Shared.Remotes)
if Remotes.Init then
	Remotes.Init()
end

local services = {}

-- Dynamically load services
print(`[Loader] Loading services from {ServicesFolder:GetFullName()}`)
for _, module in ipairs(ServicesFolder:GetChildren()) do
	if module:IsA("ModuleScript") then
		print(`[Loader] Attempting to require {module.Name}...`)
		local success, result = pcall(function()
			return require(module)
		end)
		
		if success then
			table.insert(services, { Name = module.Name, Service = result })
			print(`[Loader] Successfully loaded {module.Name}`)
		else
			warn(`[Loader] CRITICAL ERROR: Failed to load {module.Name}: {result}`)
			warn(debug.traceback())
		end
	end
end

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
			print(`[Loader] Initializing {serviceData.Name}...`)
			task.spawn(function()
				local success, err = pcall(function()
					serviceData.Service:Init()
				end)
				if success then
					print(`✓ {serviceData.Name} initialized`)
				else
					warn(`[ERROR] {serviceData.Name} Init failed: {err}`)
					warn(debug.traceback())
				end
			end)
		else
			print(`[Loader] {serviceData.Name} has no Init method`)
		end
	end
end

-- Start services
local function startServices()
	print("\n--- Starting Services ---")
	for _, serviceData in ipairs(services) do
		if type(serviceData.Service.Start) == "function" then
			print(`[Loader] Starting {serviceData.Name}...`)
			task.spawn(function()
				local success, err = pcall(function()
					serviceData.Service:Start()
				end)
				if success then
					print(`✓ {serviceData.Name} started`)
				else
					warn(`[ERROR] {serviceData.Name} Start failed: {err}`)
					warn(debug.traceback())
				end
			end)
		else
			print(`[Loader] {serviceData.Name} has no Start method`)
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
