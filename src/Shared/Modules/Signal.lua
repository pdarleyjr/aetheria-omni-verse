--[[
	Signal.lua
	A lightweight event signal implementation.
	
	API:
	Signal.new()
	Signal:Connect(callback)
	Signal:Fire(...)
	Signal:Wait()
	Signal:Destroy()
]]

local HttpService = game:GetService("HttpService")

local Signal = {}
Signal.__index = Signal
Signal.ClassName = "Signal"

function Signal.new()
	local self = setmetatable({}, Signal)
	self._bindableEvent = Instance.new("BindableEvent")
	self._argMap = {}
	self._source = "Lua"
	return self
end

function Signal:Connect(handler)
	if not (type(handler) == "function") then
		error(("connect(%s)"):format(typeof(handler)), 2)
	end

	return self._bindableEvent.Event:Connect(function(key)
		local args = self._argMap[key]
		if args then
			handler(table.unpack(args, 1, args.n))
		else
			error("Missing arg data, maybe event was fired recursively?")
		end
	end)
end

function Signal:Fire(...)
	local args = table.pack(...)
	local key = HttpService:GenerateGUID(false)
	self._argMap[key] = args

	self._bindableEvent:Fire(key)
	self._argMap[key] = nil
end

function Signal:Wait()
	local key = self._bindableEvent.Event:Wait()
	local args = self._argMap[key]
	if args then
		return table.unpack(args, 1, args.n)
	else
		return nil
	end
end

function Signal:Destroy()
	if self._bindableEvent then
		self._bindableEvent:Destroy()
		self._bindableEvent = nil
	end
	self._argMap = nil
end

return Signal
