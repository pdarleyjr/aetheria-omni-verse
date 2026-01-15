local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

print("DATA TEST: Starting...")

-- Wait for DataService to be available
local DataService
while not DataService do
	local success, result = pcall(function()
		return require(ServerScriptService.Server.Services.DataService)
	end)
	if success then
		DataService = result
	else
		task.wait(0.1)
	end
end

-- Wait for RealmService
local RealmService
while not RealmService do
	local success, result = pcall(function()
		return require(ServerScriptService.Server.Services.RealmService)
	end)
	if success then
		RealmService = result
	else
		task.wait(0.1)
	end
end

local function onPlayerAdded(player)
	-- Poll for data availability
	local data
	local attempts = 0
	while not data and attempts < 20 do
		data = DataService.GetData(player)
		if not data then
			task.wait(0.5)
			attempts = attempts + 1
		end
	end

	if data then
		print("DATA TEST: Loaded Essence: " .. data.Currencies.Essence)
		data.Currencies.Essence = data.Currencies.Essence + 50
		print("DATA TEST: Added 50 Essence. Saving...")
		
		-- Spirit Check
		task.wait(2) -- Wait for SpiritService to process
		
		local spiritCount = 0
		local firstSpiritName = "None"
		
		if data.Inventory and data.Inventory.Spirits then
			for _, spirit in pairs(data.Inventory.Spirits) do
				spiritCount = spiritCount + 1
				if firstSpiritName == "None" then
					firstSpiritName = spirit.Name
				end
			end
		end
		
		print("SPIRIT CHECK: Inventory Count = " .. spiritCount)
		print("SPIRIT CHECK: First Spirit = " .. firstSpiritName)
		
		-- Realm Test
		print("REALM TEST: Starting...")
		
		-- Wait for RealmService to initialize realm
		task.wait(2)
		
		local realmName = player.Name .. "_Realm"
		local realmModel = workspace:WaitForChild("PlayerRealms"):FindFirstChild(realmName)
		
		if realmModel and realmModel.PrimaryPart then
			print("REALM CHECK: Found Island at " .. realmModel.PrimaryPart.Position)
		else
			warn("REALM CHECK: Island NOT found in workspace.PlayerRealms!")
		end
		
		local success = RealmService:PlaceFurniture(player, "chair_01", CFrame.new(10, 5, 10))
		if success then
			print("REALM TEST: Furniture placed successfully")
		else
			warn("REALM TEST: Failed to place furniture")
		end
		
		local income = RealmService:CalculatePassiveIncome(player)
		print("REALM TEST: Passive Income: " .. income)
		
		-- Hub Return Test
		task.wait(3)
		print("TEST COMPLETE: Teleported to Hub for Combat Testing")
		
		-- Teleport to Hub
		-- We need to require WorkspaceService dynamically or assume it's loaded
		local success, WorkspaceService = pcall(function()
			return require(ServerScriptService.Server.Services.WorkspaceService)
		end)
		
		if success and WorkspaceService and WorkspaceService.TeleportToHub then
			WorkspaceService:TeleportToHub(player)
		else
			-- Manual fallback
			local hubSpawn = workspace:FindFirstChild("Hub") and workspace.Hub:FindFirstChild("SpawnLocation")
			if hubSpawn then
				player.Character:PivotTo(hubSpawn.CFrame + Vector3.new(0, 5, 0))
			end
		end
	else
		warn("DATA TEST: Could not load data for " .. player.Name)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
