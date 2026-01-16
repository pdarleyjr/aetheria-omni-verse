local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BossService = require(script.Parent.BossService)

local LiveOpsService = {}
LiveOpsService.ActiveEvents = {}

function LiveOpsService:Init()
	print("[LiveOpsService] Initializing...")
	self.Announcement = Remotes.GetEvent("Announcement")
end

function LiveOpsService:SendAnnouncement(message, color)
	self.Announcement:FireAllClients(message, color)
end

function LiveOpsService:Start()
	print("[LiveOpsService] Starting...")
end

function LiveOpsService:StartEvent(eventName)
	if self.ActiveEvents[eventName] then
		warn("[LiveOpsService] Event " .. eventName .. " is already active.")
		return
	end
	
	print("[LiveOpsService] Starting Event: " .. eventName)
	self.ActiveEvents[eventName] = true
	
	if eventName == "The Glitch Event" then
		self:StartGlitchEvent()
	end
end

function LiveOpsService:StopEvent(eventName)
	if not self.ActiveEvents[eventName] then return end
	
	print("[LiveOpsService] Stopping Event: " .. eventName)
	self.ActiveEvents[eventName] = nil
	
	-- Cleanup logic if needed
end

function LiveOpsService:StartGlitchEvent()
	-- Broadcast Message
	self.Announcement:FireAllClients("WARNING: REALITY BREACH DETECTED. THE GLITCH OVERLORD HAS ARRIVED.", Color3.fromRGB(255, 0, 0))
	
	-- Spawn Boss
	BossService:SpawnBoss("GlitchOverlord")
end

return LiveOpsService
