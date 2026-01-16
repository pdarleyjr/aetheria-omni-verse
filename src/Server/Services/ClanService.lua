--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local DataService = require(script.Parent.DataService)

local ClanService = {}
ClanService.Clans = {} -- [clanId] = ClanData
ClanService.PlayerClan = {} -- [userId] = clanId
ClanService.NextClanId = 1

function ClanService:Init()
	print("[ClanService] Initializing...")
end

function ClanService:Start()
	print("[ClanService] Starting...")
end

function ClanService:CreateClan(player: Player, name: string)
	-- Check if player is already in a clan
	if self.PlayerClan[player.UserId] then
		warn("[ClanService] Player already in a clan")
		return false
	end

	-- Check cost
	local cost = Constants.CLANS.CREATION_COST
	if not DataService.RemoveCurrency(player, cost.Currency, cost.Amount) then
		warn("[ClanService] Insufficient funds to create clan")
		return false
	end

	local clanId = self.NextClanId
	self.NextClanId = self.NextClanId + 1

	local clan = {
		Id = clanId,
		Name = name,
		OwnerId = player.UserId,
		Members = {
			[player.UserId] = "Owner"
		},
		CitadelId = "Citadel_" .. clanId
	}

	self.Clans[clanId] = clan
	self.PlayerClan[player.UserId] = clanId

	print("[ClanService] " .. player.Name .. " created clan " .. name)
	return clanId
end

function ClanService:InviteMember(player: Player, targetPlayer: Player)
	local clanId = self.PlayerClan[player.UserId]
	if not clanId then return end
	
	local clan = self.Clans[clanId]
	-- Simple permission check: Only Owner can invite for now
	if clan.Members[player.UserId] ~= "Owner" then 
		warn("[ClanService] Only owner can invite")
		return 
	end

	if self.PlayerClan[targetPlayer.UserId] then
		warn("[ClanService] Target already in a clan")
		return
	end

	-- For prototype simplicity, we'll just add them directly
	-- In production, this would send an invite request
	self:AddMember(clanId, targetPlayer)
end

function ClanService:AddMember(clanId: number, player: Player)
	local clan = self.Clans[clanId]
	if not clan then return end
	
	-- Check member limit
	local memberCount = 0
	for _ in pairs(clan.Members) do memberCount = memberCount + 1 end
	
	if memberCount >= Constants.CLANS.MAX_MEMBERS then
		warn("[ClanService] Clan is full")
		return
	end

	clan.Members[player.UserId] = "Member"
	self.PlayerClan[player.UserId] = clanId
	print("[ClanService] " .. player.Name .. " joined clan " .. clan.Name)
end

function ClanService:JoinClan(player: Player, clanId: number)
	if self.PlayerClan[player.UserId] then 
		warn("[ClanService] Already in a clan")
		return 
	end
	
	-- In a real game, this would check for an invite or if the clan is open
	-- For now, we allow joining if valid clanId
	if self.Clans[clanId] then
		self:AddMember(clanId, player)
	else
		warn("[ClanService] Clan not found")
	end
end

function ClanService:EnterCitadel(player: Player)
	local clanId = self.PlayerClan[player.UserId]
	if not clanId then 
		warn("[ClanService] Not in a clan")
		return 
	end
	
	print("[ClanService] Teleporting " .. player.Name .. " to Clan Citadel " .. clanId)
	
	if player.Character then
		-- Teleport to a conceptual citadel location (High up in the sky)
		-- Random offset to avoid stacking
		local offset = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
		player.Character:PivotTo(CFrame.new(Vector3.new(0, 2000, 0) + offset))
	end
end

function ClanService:GetClanInfo(clanId: number)
	return self.Clans[clanId]
end

return ClanService
