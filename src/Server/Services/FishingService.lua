local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

-- Assuming DataService is a ModuleScript in the same directory (Services)
local DataService = require(script.Parent.DataService)

local FishingService = {}
local activeSessions = {}

function FishingService:Init()
	print("[FishingService] Init")
	self.CastLineEvent = Remotes.GetEvent("CastLine")
	self.CatchFishEvent = Remotes.GetEvent("CatchFish")
	
	self.CastLineEvent.OnServerEvent:Connect(function(player, targetPosition)
		self:StartFishing(player, targetPosition)
	end)
	
	self.CatchFishEvent.OnServerEvent:Connect(function(player, success)
		self:ProcessCatch(player, success)
	end)
end

function FishingService:Start()
	print("[FishingService] Start")
end

function FishingService:StartFishing(player, targetPosition)
	if activeSessions[player] then 
		-- Reset session if already exists? Or deny?
		-- Let's reset for better UX if they got stuck
		activeSessions[player] = nil
	end
	
	-- Distance Check
	if targetPosition then
		local char = player.Character
		if char and char.PrimaryPart then
			local dist = (char.PrimaryPart.Position - targetPosition).Magnitude
			if dist > 50 then -- Max cast distance
				return nil
			end
		end
	end

	-- Select a fish
	-- Simple random selection for now. 
	-- In the future, use loot tables based on biome/rod.
	local fishKeys = {}
	for k, _ in pairs(Constants.FISH) do
		table.insert(fishKeys, k)
	end
	
	if #fishKeys == 0 then return nil end
	
	local selectedFishKey = fishKeys[math.random(1, #fishKeys)]
	local fishData = Constants.FISH[selectedFishKey]

	activeSessions[player] = {
		StartTime = os.time(),
		FishId = selectedFishKey,
		Difficulty = fishData.Difficulty
	}

	-- Inform client
	self.CastLineEvent:FireClient(player, {
		FishId = selectedFishKey,
		Difficulty = fishData.Difficulty,
		Rarity = fishData.Rarity
	})
	
	return {
		FishId = selectedFishKey,
		Difficulty = fishData.Difficulty,
		Rarity = fishData.Rarity
	}
end

function FishingService:ProcessCatch(player, success)
	local session = activeSessions[player]
	if not session then return false, "No active session" end

	activeSessions[player] = nil -- End session

	if success then
		-- Basic anti-cheat: Check if time elapsed is reasonable?
		-- Skipping for this phase.

		local fishId = session.FishId
		local fishData = Constants.FISH[fishId]
		
		-- Add to inventory
		local playerData = DataService.GetData(player)
		if playerData then
			if not playerData.Inventory.Items then
				playerData.Inventory.Items = {}
			end
			
			-- Stackable items logic
			local currentAmount = playerData.Inventory.Items[fishId] or 0
			playerData.Inventory.Items[fishId] = currentAmount + 1
			
			DataService.UpdateClientHUD(player)
			
			-- Notify client of success
			self.CatchFishEvent:FireClient(player, true, fishId)
			
			return true, fishId
		end
	else
		self.CatchFishEvent:FireClient(player, false)
	end

	return false, "Failed or Cancelled"
end

return FishingService
