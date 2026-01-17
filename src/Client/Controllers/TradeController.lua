--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local Maid = require(ReplicatedStorage.Shared.Modules.Maid)

local TradeController = {}
TradeController._maid = nil

-- Signals for UI to listen to
TradeController.TradeInviteReceived = Signal.new() -- (sender: Player)
TradeController.TradeUpdateReceived = Signal.new() -- (state: TradeState)
TradeController.TradeCompleted = Signal.new() -- (success: boolean)
TradeController.TradeCancelled = Signal.new() -- ()

function TradeController:Init()
	print("[TradeController] Init")
	self._maid = Maid.new()
	
	self.TradeEvent = Remotes.GetEvent("TradeEvent")
	self.TradeFunction = Remotes.GetFunction("TradeFunction")
	
	self._maid:GiveTask(self.TradeEvent.OnClientEvent:Connect(function(action, ...)
		self:HandleServerEvent(action, ...)
	end))
end

function TradeController:Start()
	print("[TradeController] Start")
end

function TradeController:HandleServerEvent(action: string, ...)
	local args = {...}
	
	if action == "TradeInvite" then
		local sender = args[1]
		print("[TradeController] Received invite from", sender)
		self.TradeInviteReceived:Fire(sender)
		
	elseif action == "UpdateTrade" then
		local state = args[1]
		self.TradeUpdateReceived:Fire(state)
		
	elseif action == "TradeComplete" then
		local success = args[1]
		self.TradeCompleted:Fire(success)
		
	elseif action == "TradeCancelled" then
		self.TradeCancelled:Fire()
	end
end

-- // API Methods for UI //

function TradeController:RequestTrade(targetPlayer: Player)
	return self.TradeFunction:InvokeServer("RequestTrade", targetPlayer)
end

function TradeController:AcceptTrade(senderPlayer: Player)
	return self.TradeFunction:InvokeServer("AcceptTrade", senderPlayer)
end

function TradeController:AddItem(category: string, itemId: string)
	return self.TradeFunction:InvokeServer("AddItem", category, itemId)
end

function TradeController:RemoveItem(category: string, itemId: string)
	return self.TradeFunction:InvokeServer("RemoveItem", category, itemId)
end

function TradeController:LockOffer()
	return self.TradeFunction:InvokeServer("LockOffer")
end

function TradeController:ConfirmTrade()
	return self.TradeFunction:InvokeServer("ConfirmTrade")
end

function TradeController:CancelTrade()
	return self.TradeFunction:InvokeServer("CancelTrade")
end

return TradeController
