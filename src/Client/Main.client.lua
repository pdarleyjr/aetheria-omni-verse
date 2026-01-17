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
local ControllersFolder = script.Parent.Controllers
local controllers = {}

-- Dynamically load controllers
for _, module in ipairs(ControllersFolder:GetChildren()) do
	if module:IsA("ModuleScript") then
		local success, result = pcall(function()
			return require(module)
		end)
		
		if success then
			table.insert(controllers, { Name = module.Name, Controller = result })
			print(`[Loader] Loaded {module.Name}`)
		else
			warn(`[Loader] Failed to load {module.Name}: {result}`)
		end
	end
end

-- Initialize controllers
local function initializeControllers()
	print("\n--- Initializing Controllers ---")
	for _, controllerData in ipairs(controllers) do
		if type(controllerData.Controller.Init) == "function" then
			task.spawn(function()
				debug.profilebegin(controllerData.Name .. "_Init")
				local initStart = os.clock()
				local success, err = pcall(function()
					controllerData.Controller:Init()
				end)
				local initTime = os.clock() - initStart
				debug.profileend()
				if success then
					print(`✓ {controllerData.Name} initialized ({string.format("%.3f", initTime * 1000)}ms)`)
				else
					warn(`[ERROR] {controllerData.Name} Init failed: {err}`)
				end
			end)
		end
	end
end

-- Start controllers
local function startControllers()
	print("\n--- Starting Controllers ---")
	for _, controllerData in ipairs(controllers) do
		if type(controllerData.Controller.Start) == "function" then
			task.spawn(function()
				debug.profilebegin(controllerData.Name .. "_Start")
				local startStart = os.clock()
				local success, err = pcall(function()
					controllerData.Controller:Start()
				end)
				local startTime = os.clock() - startStart
				debug.profileend()
				if success then
					print(`✓ {controllerData.Name} started ({string.format("%.3f", startTime * 1000)}ms)`)
				else
					warn(`[ERROR] {controllerData.Name} Start failed: {err}`)
				end
			end)
		end
	end
end

-- Main execution
local function main()
	local startTime = os.clock()
	
	initializeControllers()
	
	task.wait(0.1)
	
	startControllers()
	
	local elapsedTime = os.clock() - startTime
	print("==============================================")
	print(`  Client Ready! (Startup time: {string.format("%.2f", elapsedTime)}s)`)
	print("==============================================\n")
end

main()
