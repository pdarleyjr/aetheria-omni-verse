--[[
	SFXController.lua
	Sound effect manager with pooling for combat audio feedback
	Features: Layered sounds (charge-up, impact, reverb), element-based abilities
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Maid = require(ReplicatedStorage.Shared.Modules.Maid)

local SFXController = {}
SFXController._maid = nil
SFXController._soundPools = {}
SFXController._reverbGroup = nil

-- Sound IDs organized by category
local SOUND_IDS = {
	-- Hit sounds (using valid Roblox library sounds)
	HIT_NORMAL = "rbxassetid://3932505589", -- Generic hit sound
	HIT_CRITICAL = "rbxassetid://3932505589", -- Critical hit (same base, pitch modified)
	HIT_FIRE = "rbxassetid://5152319836",
	HIT_ICE = "rbxassetid://9113926617",
	HIT_LIGHTNING = "rbxassetid://9114270126",
	
	-- Ability layers: Charge-up
	CHARGE_FIREBALL = "rbxassetid://9113651830",
	CHARGE_DASH = "rbxassetid://9113651830",
	CHARGE_ICE = "rbxassetid://9113926617",
	
	-- Ability layers: Impact
	IMPACT_FIREBALL = "rbxassetid://5152319836",
	IMPACT_DASH = "rbxassetid://9113651830",
	IMPACT_ICE = "rbxassetid://9113926617",
	
	-- General SFX (using valid Roblox library sounds)
	ENEMY_DEATH = "rbxassetid://6518811702", -- Valid defeat/death sound
	CURRENCY_PICKUP = "rbxassetid://4612373953", -- Valid pickup/coin sound
	UI_CLICK = "rbxassetid://9114270126",
	LEVEL_UP = "rbxassetid://9114277900",
}

-- Element-specific pitch/volume modifiers
local ELEMENT_MODIFIERS = {
	Fire = { pitch = 1.0, volume = 0.7 },
	Ice = { pitch = 0.9, volume = 0.6 },
	Lightning = { pitch = 1.2, volume = 0.8 },
	Physical = { pitch = 1.0, volume = 0.5 },
}

-- Pitch variation range for impact sounds
local PITCH_VARIATION_MIN = 0.9
local PITCH_VARIATION_MAX = 1.1

local POOL_SIZE = 5
local CRITICAL_POOL_SIZE = 3 -- Separate pool for critical hit layer

function SFXController:Init()
	print("[SFXController] Initializing...")
	self._maid = Maid.new()
	self._soundPools = {}
	
	-- Create reverb sound group for environmental sounds
	self:CreateReverbGroup()
	
	-- Pre-create sound pools for commonly used sounds
	self:CreateSoundPool("HIT_NORMAL", SOUND_IDS.HIT_NORMAL)
	self:CreateSoundPool("HIT_CRITICAL", SOUND_IDS.HIT_CRITICAL)
	self:CreateSoundPool("CRITICAL_LAYER", SOUND_IDS.HIT_CRITICAL) -- Separate layer for crit stacking
	self:CreateSoundPool("ENEMY_DEATH", SOUND_IDS.ENEMY_DEATH)
	self:CreateSoundPool("CURRENCY_PICKUP", SOUND_IDS.CURRENCY_PICKUP)
end

function SFXController:Start()
	print("[SFXController] Starting...")
	
	-- Listen for combat hit events
	local OnCombatHit = Remotes.GetEvent("OnCombatHit")
	if OnCombatHit then
		self._maid:GiveTask(OnCombatHit.OnClientEvent:Connect(function(hitData)
			self:PlayHitSound(hitData.damageType, hitData.isCritical)
		end))
	end
	
	-- Listen for enemy death
	local EnemyDeath = Remotes.GetEvent("EnemyDeath")
	if EnemyDeath then
		self._maid:GiveTask(EnemyDeath.OnClientEvent:Connect(function()
			self:PlayEnemyDeathSound()
		end))
	end
	
	-- Listen for currency drops
	local CurrencyDrop = Remotes.GetEvent("CurrencyDrop")
	if CurrencyDrop then
		self._maid:GiveTask(CurrencyDrop.OnClientEvent:Connect(function()
			self:PlaySound("CURRENCY_PICKUP")
		end))
	end
	
	-- Listen for ability usage
	local AbilityUsed = Remotes.GetEvent("AbilityUsed")
	if AbilityUsed then
		self._maid:GiveTask(AbilityUsed.OnClientEvent:Connect(function(abilityName, phase)
			self:PlayAbilityLayeredSound(abilityName, phase)
		end))
	end
end

function SFXController:CreateReverbGroup()
	self._reverbGroup = Instance.new("SoundGroup")
	self._reverbGroup.Name = "ReverbGroup"
	self._reverbGroup.Volume = 0.6
	self._reverbGroup.Parent = SoundService
	
	-- Add reverb effect for environmental sounds
	local reverb = Instance.new("ReverbSoundEffect")
	reverb.DecayTime = 1.5
	reverb.Density = 0.8
	reverb.Diffusion = 0.7
	reverb.DryLevel = 0
	reverb.WetLevel = -6
	reverb.Parent = self._reverbGroup
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
	
	for _, sound in ipairs(pool) do
		if not sound.IsPlaying then
			return sound
		end
	end
	
	return pool[1]
end

function SFXController:PlaySound(name, volume, pitch)
	local sound = self:GetPooledSound(name)
	if not sound then return end
	
	sound.Volume = volume or 0.5
	sound.PlaybackSpeed = pitch or 1
	sound:Play()
end

-- Play sound with random pitch variation (0.9-1.1)
function SFXController:PlaySoundWithPitchVariation(name, volume, basePitch)
	local pitchVariation = PITCH_VARIATION_MIN + math.random() * (PITCH_VARIATION_MAX - PITCH_VARIATION_MIN)
	local finalPitch = (basePitch or 1) * pitchVariation
	self:PlaySound(name, volume, finalPitch)
end

function SFXController:PlayHitSound(damageType, isCritical)
	local modifiers = ELEMENT_MODIFIERS[damageType] or ELEMENT_MODIFIERS.Physical
	
	-- Apply pitch variation (0.9-1.1) to all impact sounds
	local pitchVariation = PITCH_VARIATION_MIN + math.random() * (PITCH_VARIATION_MAX - PITCH_VARIATION_MIN)
	
	if isCritical then
		-- Main critical hit sound
		self:PlaySound("HIT_CRITICAL", 0.8 * modifiers.volume, modifiers.pitch * pitchVariation)
		-- Separate critical hit layer (louder, slightly different pitch for layered effect)
		task.delay(0.02, function()
			self:PlaySound("CRITICAL_LAYER", 0.6, modifiers.pitch * 1.15 * pitchVariation)
		end)
	else
		self:PlaySound("HIT_NORMAL", 0.5 * modifiers.volume, modifiers.pitch * pitchVariation)
	end
	
	-- Play element-specific hit layer if exists
	local elementHitKey = "HIT_" .. string.upper(damageType or "PHYSICAL")
	if self._soundPools[elementHitKey] then
		self:PlaySoundWithPitchVariation(elementHitKey, 0.3, modifiers.pitch)
	end
end

function SFXController:PlayAbilityLayeredSound(abilityName, phase)
	-- Layered sound structure: charge-up, impact, reverb
	phase = phase or "impact"
	
	local chargeKey = "CHARGE_" .. string.upper(abilityName)
	local impactKey = "IMPACT_" .. string.upper(abilityName)
	
	if phase == "charge" then
		-- Create on-demand if not pooled
		local soundId = SOUND_IDS[chargeKey]
		if soundId then
			self:PlayOneShot(soundId, 0.4, 0.8)
		end
	elseif phase == "impact" then
		local soundId = SOUND_IDS[impactKey]
		if soundId then
			self:PlayOneShot(soundId, 0.6, 1.0)
			-- Also play reverb layer
			self:PlayReverbLayer(soundId)
		end
	end
end

function SFXController:PlayOneShot(soundId, volume, pitch)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function SFXController:PlayReverbLayer(soundId)
	if not self._reverbGroup then return end
	
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.2
	sound.PlaybackSpeed = 0.7
	sound.SoundGroup = self._reverbGroup
	sound.Parent = SoundService
	
	task.delay(0.1, function()
		sound:Play()
	end)
	
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function SFXController:PlayEnemyDeathSound()
	self:PlaySound("ENEMY_DEATH", 0.6, 0.9 + math.random() * 0.2)
end

function SFXController:PlayCriticalSound()
	self:PlaySound("HIT_CRITICAL", 0.8, 1.0)
end

function SFXController:Cleanup()
	if self._maid then
		self._maid:Destroy()
	end
	if self._reverbGroup then
		self._reverbGroup:Destroy()
	end
end

return SFXController
