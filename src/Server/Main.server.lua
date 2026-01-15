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
local Services = ServerScriptService.Server.Services

local DataService = require(Services.DataService)
local PlayerService = require(Services.PlayerService)
local RealmService = require(Services.RealmService)
local SpiritService = require(Services.SpiritService)
local WorkspaceService = require(Services.WorkspaceService)
local CombatService = require(Services.CombatService)

-- Remotes initialization
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- Track initialization status
local initializationSteps = {
	{ Name = "DataService", Service = DataService, Status = "Pending" },
	{ Name = "PlayerService", Service = PlayerService, Status = "Pending" },
	{ Name = "RealmService", Service = RealmService, Status = "Pending" },
	{ Name = "SpiritService", Service = SpiritService, Status = "Pending" },
	{ Name = "WorkspaceService", Service = WorkspaceService, Status = "Pending" },
	{ Name = "CombatService", Service = CombatService, Status = "Pending" },
}

-- Global error handler
local function handleError(context: string, err: string): ()
	warn(`[ERROR] {context}: {err}`)
	warn(debug.traceback())
end

-- Initialize services in order
local function initializeServices(): boolean
	print("\n--- Initializing Services ---")
	
	for _, step in initializationSteps do
		local success, err = pcall(function()
			step.Service:Init()
			step.Status = "Initialized"
			print(`✓ {step.Name} initialized`)
		end)
		
		if not success then
			step.Status = "Failed"
			handleError(`Initialization of {step.Name}`, err)
			return false
		end
	end
	
	print("✓ All services initialized successfully\n")
	return true
end

-- Start services
local function startServices(): boolean
	print("--- Starting Services ---")
	
	for _, step in initializationSteps do
		local success, err = pcall(function()
			step.Service:Start()
			step.Status = "Running"
			print(`✓ {step.Name} started`)
		end)
		
		if not success then
			step.Status = "Failed"
			handleError(`Starting {step.Name}`, err)
			return false
		end
	end
	
	print("✓ All services started successfully\n")
	return true
end

-- Main execution
local function main(): ()
	local startTime = os.clock()
	
	-- Step 0: Initialize Remote Events FIRST
	print("\n--- Initializing Remote Events ---")
	Remotes.InitializeRemotes()
	print("✓ Remote Events initialized\n")
	
	-- Step 1: Initialize all services
	local initSuccess = initializeServices()
	if not initSuccess then
		error("Failed to initialize services - server cannot start")
		return
	end
	
	-- Step 2: Start all services
	local startSuccess = startServices()
	if not startSuccess then
		error("Failed to start services - server cannot start")
		return
	end
	
	-- Calculate startup time
	local elapsedTime = os.clock() - startTime
	
	print("==============================================")
	print(`  Server Ready! (Startup time: {string.format("%.2f", elapsedTime)}s)`)
	print("==============================================\n")
	
	-- Server is now ready to accept players
	print("Waiting for players to join...")
end

-- Protected call to main
local success, err = pcall(main)

if not success then
	handleError("Server Startup", err)
	error("FATAL: Server failed to start")
end
