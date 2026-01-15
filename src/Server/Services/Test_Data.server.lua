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

local function onPlayerAdded(player)
	-- Poll for data availability
	local data
	local attempts = 0
	while not data and attempts < 20 do
		data = DataService.GetData(player)
		if not data then
			task.wait(0.5)
			attempts += 1
		end
	end

	if data then
		print("DATA TEST: Loaded Essence: " .. data.Currencies.Essence)
		data.Currencies.Essence += 50
		print("DATA TEST: Added 50 Essence. Saving...")
	else
		warn("DATA TEST: Could not load data for " .. player.Name)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
