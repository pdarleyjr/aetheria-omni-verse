--!strict
--[[
	PlayerService.lua
	Handles player lifecycle events (joining/leaving), data initialization,
	and leaderstats setup.
	
	Features:
	- Player join/leave event handling
	- Data loading with retry logic
	- Leaderstats setup for visibility
	- Integration with DataService
	- Character respawn management
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Only run on server
if not RunService:IsServer() then
	error("PlayerService can only be required on the server")
end

-- Services
local DataService = require(ServerScriptService.Server.Services.DataService)
local SpiritService = require(ServerScriptService.Server.Services.SpiritService)

-- Types
type PlayerData = {
	UserId: number,
	DisplayName: string,
	Currencies: {
		Aether: number,
		Essence: number,
	},
	Stats: {
		Level: number,
		Experience: number,
	},
}

-- Constants
local KICK_ON_LOAD_FAIL = true
local LOAD_TIMEOUT = 30

-- Service
local PlayerService = {}

-- Create leaderstats for player
local function setupLeaderstats(player: Player, data: PlayerData): ()
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	-- Level
	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = data.Stats.Level
	level.Parent = leaderstats
	
	-- Essence (main currency)
	local essence = Instance.new("IntValue")
	essence.Name = "Essence"
	essence.Value = data.Currencies.Essence
	essence.Parent = leaderstats
	
	-- Aether (premium currency)
	local aether = Instance.new("IntValue")
	aether.Name = "Aether"
	aether.Value = data.Currencies.Aether
	aether.Parent = leaderstats
end

-- Update leaderstats from data
local function updateLeaderstats(player: Player, data: PlayerData): ()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	
	local level = leaderstats:FindFirstChild("Level") :: IntValue?
	if level then
		level.Value = data.Stats.Level
	end
	
	local essence = leaderstats:FindFirstChild("Essence") :: IntValue?
	if essence then
		essence.Value = data.Currencies.Essence
	end
	
	local aether = leaderstats:FindFirstChild("Aether") :: IntValue?
	if aether then
		aether.Value = data.Currencies.Aether
	end
end

-- Handle player joining
local function onPlayerAdded(player: Player): ()
	print(`Player {player.Name} is joining...`)
	
	-- Load player profile with timeout
	local loadSuccess = false
	local profile = nil
	
	task.spawn(function()
		profile = DataService:LoadPlayerProfile(player)
		loadSuccess = profile ~= nil
	end)
	
	-- Wait for load with timeout
	local startTime = os.clock()
	while not loadSuccess and (os.clock() - startTime) < LOAD_TIMEOUT do
		task.wait(0.1)
	end
	
	if not loadSuccess or not profile then
		warn(`Failed to load profile for {player.Name}`)
		if KICK_ON_LOAD_FAIL then
			player:Kick("Failed to load your data. Please try rejoining.")
		end
		return
	end
	
	local data = profile.Data
	
	-- Setup leaderstats
	setupLeaderstats(player, data)
	
	-- Award starting spirit if new player
	if not data.Spirits or next(data.Spirits) == nil then
		print(`New player detected - awarding starting spirit to {player.Name}`)
		SpiritService:AwardSpirit(player, "fire_spirit")
	end
	
	-- Handle character spawning
	local function onCharacterAdded(character: Model)
		print(`Character spawned for {player.Name}`)
		
		-- Wait for humanoid
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if not humanoid then
			return
		end
		
		-- Apply any saved character modifications here
		-- (e.g., spawn with Spirit companions)
	end
	
	-- Connect to character events
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
	
	print(`Player {player.Name} successfully joined`)
end

-- Handle player leaving
local function onPlayerRemoving(player: Player): ()
	print(`Player {player.Name} is leaving...`)
	
	-- Data cleanup is handled by DataService
end

-- Initialize service
function PlayerService:Init(): ()
	print("Initializing PlayerService...")
	print("PlayerService initialized")
end

-- Start service
function PlayerService:Start(): ()
	print("Starting PlayerService...")
	
	-- Connect player events
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	
	-- Handle players who joined before this script ran
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	
	print("PlayerService started")
end

-- Update player leaderstats (called by other services when data changes)
function PlayerService:UpdateLeaderstats(player: Player): ()
	local data = DataService:GetPlayerData(player)
	if data then
		updateLeaderstats(player, data)
	end
end

-- Get player's character safely
function PlayerService:GetCharacter(player: Player): Model?
	return player.Character
end

-- Get player's humanoid safely
function PlayerService:GetHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	
	return character:FindFirstChild("Humanoid") :: Humanoid?
end

-- Check if player is alive
function PlayerService:IsPlayerAlive(player: Player): boolean
	local humanoid = self:GetHumanoid(player)
	return humanoid ~= nil and humanoid.Health > 0
end

-- Respawn player
function PlayerService:RespawnPlayer(player: Player): ()
	task.spawn(function()
		player:LoadCharacter()
	end)
end

-- Damage player
function PlayerService:DamagePlayer(player: Player, damage: number): ()
	local humanoid = self:GetHumanoid(player)
	if humanoid then
		humanoid:TakeDamage(damage)
	end
end

-- Heal player
function PlayerService:HealPlayer(player: Player, amount: number): ()
	local humanoid = self:GetHumanoid(player)
	if humanoid then
		humanoid.Health = math.min(humanoid.Health + amount, humanoid.MaxHealth)
	end
end

-- Teleport player to position
function PlayerService:TeleportToPosition(player: Player, cframe: CFrame): ()
	local character = self:GetCharacter(player)
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: Part?
		if humanoidRootPart then
			humanoidRootPart.CFrame = cframe
		end
	end
end

return PlayerService
