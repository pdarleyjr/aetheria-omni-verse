--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
-- We access DataService via _G or require. Since they are siblings, require is tricky if circular.
-- But TradeService depends on DataService, DataService doesn't depend on TradeService.
-- So we can try to require it, or use _G.GetData / _G.UpdateHUD
-- Using _G is safer given the current setup in DataService.lua
-- But for the new methods (MoveToEscrow), we need the module table.
-- We'll assume DataService is loaded first.
local DataService -- Will be required in Init to avoid load order issues if possible, or just require here.

local TradeService = {}
TradeService.Sessions = {}

-- Types
type TradeOffer = {
	Spirits: {[string]: any},
	Items: {[string]: any}
}

type TradeSession = {
	Partner: Player,
	Offer: TradeOffer,
	Locked: boolean,
	Confirmed: boolean
}

function TradeService:Init()
	print("[TradeService] Init")
	
	-- Lazy load DataService to ensure it's ready
	DataService = require(script.Parent.DataService)
	
	self.TradeEvent = Remotes.GetEvent("TradeEvent")
	self.RequestTradeFunc = Remotes.GetFunction("RequestTrade")
	self.RequestTradeFunc.OnServerInvoke = function(player, target)
		return self:RequestTrade(player, target)
	end
	
	self.TradeFunction = Remotes.GetFunction("TradeFunction")
	self.TradeFunction.OnServerInvoke = function(player, action, ...)
		return self:HandleClientRequest(player, action, ...)
	end
	
	Players.PlayerRemoving:Connect(function(player)
		self:CancelTrade(player)
	end)
end

function TradeService:Start()
	print("[TradeService] Start")
end

function TradeService:HandleClientRequest(player: Player, action: string, ...): any
	local args = {...}
	
	if action == "RequestTrade" then
		local target = args[1]
		return self:RequestTrade(player, target)
	elseif action == "AcceptTrade" then
		local sender = args[1]
		return self:AcceptTrade(player, sender)
	elseif action == "AddItem" then
		return self:AddItem(player, args[1], args[2]) -- category, itemId
	elseif action == "RemoveItem" then
		return self:RemoveItem(player, args[1], args[2])
	elseif action == "LockOffer" then
		return self:LockOffer(player)
	elseif action == "ConfirmTrade" then
		return self:ConfirmTrade(player)
	elseif action == "CancelTrade" then
		return self:CancelTrade(player)
	end
	
	return false
end

function TradeService:RequestTrade(sender: Player, target: Player)
	if sender == target then return false end
	if self.Sessions[sender] or self.Sessions[target] then return false, "Busy" end
	
	-- Send invite to target
	self.TradeEvent:FireClient(target, "TradeInvite", sender)
	return true
end

function TradeService:AcceptTrade(receiver: Player, sender: Player)
	if self.Sessions[receiver] or self.Sessions[sender] then return false, "Busy" end
	
	-- Start Session
	self:CreateSession(sender, receiver)
	return true
end

function TradeService:CreateSession(p1: Player, p2: Player)
	self.Sessions[p1] = {
		Partner = p2,
		Offer = { Spirits = {}, Items = {} },
		Locked = false,
		Confirmed = false
	}
	self.Sessions[p2] = {
		Partner = p1,
		Offer = { Spirits = {}, Items = {} },
		Locked = false,
		Confirmed = false
	}
	
	self:UpdateClients(p1, p2)
end

function TradeService:UpdateClients(p1: Player, p2: Player)
	local s1 = self.Sessions[p1]
	local s2 = self.Sessions[p2]
	
	if not s1 or not s2 then return end
	
	local state1 = {
		Partner = p2.Name,
		MyOffer = s1.Offer,
		PartnerOffer = s2.Offer,
		MyStatus = { Locked = s1.Locked, Confirmed = s1.Confirmed },
		PartnerStatus = { Locked = s2.Locked, Confirmed = s2.Confirmed }
	}
	
	local state2 = {
		Partner = p1.Name,
		MyOffer = s2.Offer,
		PartnerOffer = s1.Offer,
		MyStatus = { Locked = s2.Locked, Confirmed = s2.Confirmed },
		PartnerStatus = { Locked = s1.Locked, Confirmed = s1.Confirmed }
	}
	
	self.TradeEvent:FireClient(p1, "UpdateTrade", state1)
	self.TradeEvent:FireClient(p2, "UpdateTrade", state2)
end

function TradeService:AddItem(player: Player, category: string, itemId: string)
	local session = self.Sessions[player]
	if not session then return false end
	if session.Locked then return false end
	
	-- Attempt to move to Escrow
	local success = DataService.MoveToEscrow(player, category, itemId)
	if success then
		session.Offer[category][itemId] = true -- Just store ID or minimal data
		
		-- Reset Locks (Two-Step Verification)
		session.Locked = false
		session.Confirmed = false
		
		local partnerSession = self.Sessions[session.Partner]
		if partnerSession then
			partnerSession.Locked = false
			partnerSession.Confirmed = false
			self:UpdateClients(player, session.Partner)
		end
		return true
	end
	return false
end

function TradeService:RemoveItem(player: Player, category: string, itemId: string)
	local session = self.Sessions[player]
	if not session then return false end
	if session.Locked then return false end
	
	if session.Offer[category][itemId] then
		local success = DataService.RestoreFromEscrow(player, category, itemId)
		if success then
			session.Offer[category][itemId] = nil
			
			-- Reset Locks
			session.Locked = false
			session.Confirmed = false
			local partnerSession = self.Sessions[session.Partner]
			if partnerSession then
				partnerSession.Locked = false
				partnerSession.Confirmed = false
				self:UpdateClients(player, session.Partner)
			end
			return true
		end
	end
	return false
end

function TradeService:LockOffer(player: Player)
	local session = self.Sessions[player]
	if not session then return false end
	
	session.Locked = true
	self:UpdateClients(player, session.Partner)
	return true
end

function TradeService:ConfirmTrade(player: Player)
	local session = self.Sessions[player]
	if not session then return false end
	
	local partnerSession = self.Sessions[session.Partner]
	if not partnerSession then return false end
	
	if not session.Locked or not partnerSession.Locked then return false end
	
	session.Confirmed = true
	self:UpdateClients(player, session.Partner)
	
	if partnerSession.Confirmed then
		self:ExecuteTrade(player, session.Partner)
	end
	return true
end

function TradeService:ExecuteTrade(p1: Player, p2: Player)
	local s1 = self.Sessions[p1]
	local s2 = self.Sessions[p2]
	
	if not s1 or not s2 then return end
	
	local success = DataService.ExecuteTrade(p1, p2, s1.Offer, s2.Offer)
	
	if success then
		-- Clear sessions without restoring items (they are swapped)
		self.Sessions[p1] = nil
		self.Sessions[p2] = nil
		
		self.TradeEvent:FireClient(p1, "TradeComplete", true)
		self.TradeEvent:FireClient(p2, "TradeComplete", true)
	else
		-- Fallback: Cancel and restore
		self:CancelTrade(p1) -- This will handle p2 as well via partner link
	end
end

function TradeService:CancelTrade(player: Player)
	local session = self.Sessions[player]
	if not session then return end
	
	local partner = session.Partner
	local partnerSession = self.Sessions[partner]
	
	-- Restore items for player
	for category, items in pairs(session.Offer) do
		for itemId, _ in pairs(items) do
			DataService.RestoreFromEscrow(player, category, itemId)
		end
	end
	
	-- Restore items for partner
	if partnerSession then
		for category, items in pairs(partnerSession.Offer) do
			for itemId, _ in pairs(items) do
				DataService.RestoreFromEscrow(partner, category, itemId)
			end
		end
		self.Sessions[partner] = nil
		self.TradeEvent:FireClient(partner, "TradeCancelled")
	end
	
	self.Sessions[player] = nil
	self.TradeEvent:FireClient(player, "TradeCancelled")
end

return TradeService
