--[[
	SFXController.lua
	Sound effect manager with pooling for combat audio feedback
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Maid = require(ReplicatedStorage.Shared.Modules.Maid)

local SFXController = {}
SFXController._maid = nil
SFXController._soundPools = {}

-- Valid Roblox Sound IDs for game audio feedback
local SOUND_IDS = {
	HIT_NORMAL = "rbxassetid://9114076965", -- Punch/hit impact
	HIT_CRITICAL = "rbxassetid://9114177619", -- Heavy critical hit impact
	ABILITY_Fireball = "rbxassetid://5152319836", -- Fireball/explosion whoosh
	ABILITY_Dash = "rbxassetid://9113651830", -- Dash/swoosh sound
	ENEMY_DEATH = "rbxassetid://4529579271", -- Enemy death/defeat sound
	CURRENCY_PICKUP = "rbxassetid://9120484367", -- Coin/currency pickup chime
	UI_CLICK = "rbxassetid://9114270126", -- UI button click
	LEVEL_UP = "rbxassetid://9114277900", -- Level up fanfare
}

local POOL_SIZE = 5

function SFXController:Init()
	print("[SFXController] Initializing...")
	self._maid = Maid.new()
	self._soundPools = {}
	
	-- Pre-create sound pools
	for name, soundId in pairs(SOUND_IDS) do
		-- Only create pools for names that don't end with underscores
		if not name:find("_") then
			self:CreateSoundPool(name, soundId)
		end
	end
end

function SFXController:Start()
	print("[SFXController] Starting...")
	
	-- Listen for combat hit events
	local OnCombatHit = Remotes.GetEvent("OnCombatHit")
	if OnCombatHit then
		self._maid:GiveTask(OnCombatHit.OnClientEvent:Connect(function(hitData)
			if hitData.isCritical then
				self:PlayCriticalSound()
			else
				self:PlayHitSound()
			end
		end))
	end
	
	-- Listen for currency drops
	local CurrencyDrop = Remotes.GetEvent("CurrencyDrop")
	if CurrencyDrop then
		self._maid:GiveTask(CurrencyDrop.OnClientEvent:Connect(function(currency, amount)
			self:PlaySound("CURRENCY_PICKUP")
		end))
	end
end

function SFXController:CreateSoundPool(name, soundId)
	self._soundPools[name] = {}
	
	for i = 1, POOL_SIZE do
		local sound = Instance.new("Sound")
		sound.Name = name .. "_" .. i
		sound.SoundId = soundId
		sound.Volume = 0.5
		sound.Parent = SoundService
		table.insert(self._soundPools[name], sound)
	end
end

function SFXController:GetPooledSound(name)
	local pool = self._soundPools[name]
	if not pool then return nil end
	
	-- Find available (not playing) sound
	for _, sound in ipairs(pool) do
		if not sound.IsPlaying then
			return sound
		end
	end
	
	-- All busy, return first one (will restart)
	return pool[1]
end

function SFXController:PlaySound(name, volume, pitch)
	local sound = self:GetPooledSound(name)
	if not sound then return end
	
	sound.Volume = volume or 0.5
	sound.PlaybackSpeed = pitch or 1
	sound:Play()
end

function SFXController:PlayHitSound()
	self:PlaySound("HIT_NORMAL", 0.5, 0.9 + math.random() * 0.2)
end

function SFXController:PlayCriticalSound()
	self:PlaySound("HIT_CRITICAL", 0.8, 1.0)
end

function SFXController:PlayAbilitySound(abilityName)
	local soundKey = "ABILITY_" .. abilityName
	if self._soundPools[soundKey] then
		self:PlaySound(soundKey, 0.6, 1.0)
	else
		print("[SFXController] No sound found for ability: " .. abilityName)
	end
end

function SFXController:PlayEnemyDeathSound()
	self:PlaySound("ENEMY_DEATH", 0.6, 0.9 + math.random() * 0.2)
end

function SFXController:Cleanup()
	if self._maid then
		self._maid:Destroy()
	end
end

return SFXController
