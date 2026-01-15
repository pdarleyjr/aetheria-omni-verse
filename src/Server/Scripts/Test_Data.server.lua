local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Safety check: Only run in Studio to prevent production issues
if not RunService:IsStudio() then
	return
end

print("DATA TEST: Starting (Studio Mode)...")

local function safeRequire(modulePath)
	local success, result = pcall(function()
		return require(modulePath)
	end)
	if success then
		return result
	else
		warn("DATA TEST: Failed to require " .. tostring(modulePath) .. ": " .. tostring(result))
		return nil
	end
end

-- Run in a separate thread to avoid blocking
task.spawn(function()
	-- Allow core services to initialize
	task.wait(2)

	local DataService = safeRequire(ServerScriptService.Server.Services.DataService)
	local RealmService = safeRequire(ServerScriptService.Server.Services.RealmService)
	
	if not DataService or not RealmService then
		warn("DATA TEST: Critical services missing. Aborting test.")
		return
	end

	local function onPlayerAdded(player)
		-- Wait for data to load with timeout
		local attempts = 0
		local data = nil
		while attempts < 10 do
			data = DataService.GetData(player)
			if data then break end
			task.wait(1)
			attempts += 1
		end

		if not data then
			warn("DATA TEST: Could not get data for " .. player.Name)
			return
		end

		print("DATA TEST: Loaded Essence: " .. tostring(data.Currencies.Essence))
		
		-- Add test currency if low
		if data.Currencies.Essence < 100 then
			DataService.AddCurrency(player, "Essence", 100)
			print("DATA TEST: Added 100 Essence (Starter Bonus)")
		end
		
		-- Verify Realm
		task.wait(1)
		local income = RealmService:CalculatePassiveIncome(player)
		print("DATA TEST: Passive Income Check: " .. tostring(income))
		
		print("DATA TEST: Player " .. player.Name .. " ready for testing.")
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end)
