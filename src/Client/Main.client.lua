--!strict
--[[
	Main.client.lua
	Client entry point for Aetheria: The Omni-Verse
	
	Initializes all client controllers in proper dependency order.
	Waits for player and character to load before enabling UI.
	
	Initialization Flow:
	1. Wait for LocalPlayer and Character
	2. Wait for ReplicatedStorage to be ready
	3. Initialize Controllers
	4. Start Controllers
	5. Enable UI
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")

-- Only run on client
if not RunService:IsClient() then
	error("Main.client.lua can only run on the client")
end

print("==============================================")
print("  Aetheria: The Omni-Verse - Client Starting")
print("==============================================")

-- Wait for LocalPlayer
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	error("LocalPlayer not found")
end

-- Controller requires
local Controllers = script.Parent.Controllers

local UIController = require(Controllers.UIController)
local CombatController = require(Controllers.CombatController)

-- Track initialization status
local initializationSteps = {
	{ Name = "UIController", Controller = UIController, Status = "Pending" },
	{ Name = "CombatController", Controller = CombatController, Status = "Pending" },
}

-- Global error handler
local function handleError(context: string, err: string): ()
	warn(`[ERROR] {context}: {err}`)
	warn(debug.traceback())
end

-- Wait for character to load
local function waitForCharacter(): Model?
	local character = LocalPlayer.Character
	if not character then
		character = LocalPlayer.CharacterAdded:Wait()
	end
	
	-- Wait for humanoid
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		warn("Failed to find Humanoid in character")
		return nil
	end
	
	return character
end

-- Initialize controllers
local function initializeControllers(): boolean
	print("\n--- Initializing Controllers ---")
	
	for _, step in initializationSteps do
		local success, err = pcall(function()
			step.Controller:Init()
			step.Status = "Initialized"
			print(`✓ {step.Name} initialized`)
		end)
		
		if not success then
			step.Status = "Failed"
			handleError(`Initialization of {step.Name}`, err)
			return false
		end
	end
	
	print("✓ All controllers initialized successfully\n")
	return true
end

-- Start controllers
local function startControllers(): boolean
	print("--- Starting Controllers ---")
	
	for _, step in initializationSteps do
		local success, err = pcall(function()
			step.Controller:Start()
			step.Status = "Running"
			print(`✓ {step.Name} started`)
		end)
		
		if not success then
			step.Status = "Failed"
			handleError(`Starting {step.Name}`, err)
			return false
		end
	end
	
	print("✓ All controllers started successfully\n")
	return true
end

-- Create RemoteEvent references (created by server)
local function setupRemotes(): boolean
	-- Wait for Remotes folder to be created by server
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes then
		warn("Failed to find Remotes folder in ReplicatedStorage")
		return false
	end
	
	-- Create Combat folder if it doesn't exist (server should have done this)
	local combatFolder = remotes:FindFirstChild("Combat")
	if not combatFolder then
		warn("Combat remotes not found - server may not be ready")
		return false
	end
	
	-- Cache remote references
	_G.Remotes = {
		Combat = {
			RequestAttack = combatFolder:WaitForChild("RequestAttack", 5),
			HitConfirmed = combatFolder:WaitForChild("HitConfirmed", 5),
			AbilityCast = combatFolder:WaitForChild("AbilityCast", 5),
			DamageNumber = combatFolder:WaitForChild("DamageNumber", 5),
		},
		Data = {
			DataChanged = remotes:FindFirstChild("Data") and remotes.Data:FindFirstChild("DataChanged"),
			ReplicateData = remotes:FindFirstChild("Data") and remotes.Data:FindFirstChild("ReplicateData"),
		},
	}
	
	print("✓ Remote references cached")
	return true
end

-- Main execution
local function main(): ()
	local startTime = os.clock()
	
	print(`Client initializing for player: {LocalPlayer.Name}`)
	
	-- Step 1: Wait for character
	print("\n--- Waiting for Character ---")
	local character = waitForCharacter()
	if not character then
		error("Failed to load character - cannot start client")
		return
	end
	print(`✓ Character loaded: {character.Name}`)
	
	-- Step 2: Setup remote references
	print("\n--- Setting up Remotes ---")
	local remotesReady = setupRemotes()
	if not remotesReady then
		warn("Remotes not fully ready - some features may not work")
	end
	
	-- Step 3: Initialize all controllers
	local initSuccess = initializeControllers()
	if not initSuccess then
		error("Failed to initialize controllers - client cannot start")
		return
	end
	
	-- Step 4: Start all controllers
	local startSuccess = startControllers()
	if not startSuccess then
		error("Failed to start controllers - client cannot start")
		return
	end
	
	-- Calculate startup time
	local elapsedTime = os.clock() - startTime
	
	print("==============================================")
	print(`  Client Ready! (Startup time: {string.format("%.2f", elapsedTime)}s)`)
	print("==============================================\n")
	
	-- Handle character respawn
	LocalPlayer.CharacterAdded:Connect(function(newCharacter)
		print(`Character respawned: {newCharacter.Name}`)
		-- Notify controllers of respawn
		for _, step in initializationSteps do
			if step.Controller.OnCharacterRespawn then
				pcall(function()
					step.Controller:OnCharacterRespawn(newCharacter)
				end)
			end
		end
	end)
end

-- Protected call to main
local success, err = pcall(main)

if not success then
	handleError("Client Startup", err)
	error("FATAL: Client failed to start")
end
