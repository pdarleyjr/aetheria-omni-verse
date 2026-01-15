--!strict

--[[
	Signal.lua
	
	A custom event system similar to RBXScriptSignal.
	Provides a type-safe event implementation for communication between modules.
	
	Usage:
		local mySignal = Signal.new()
		
		-- Connect a listener
		local connection = mySignal:Connect(function(value)
			print("Received:", value)
		end)
		
		-- Fire the signal
		mySignal:Fire("Hello!")
		
		-- Disconnect
		connection:Disconnect()
		
		-- Or disconnect all
		mySignal:DisconnectAll()
		
	@class Signal
]]

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Wait: (self: Signal<T...>) -> T...,
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
	Destroy: (self: Signal<T...>) -> (),
}

type SignalInternal<T...> = Signal<T...> & {
	_connections: { Connection },
	_bindableEvent: BindableEvent?,
}

local Signal = {}
Signal.__index = Signal

--[=[
	Creates a new Signal instance.
	
	@return Signal<T...> -- The new signal
]=]
function Signal.new<T...>(): Signal<T...>
	local self = setmetatable({
		_connections = {},
		_bindableEvent = nil,
	}, Signal) :: any
	
	return self :: Signal<T...>
end

--[=[
	Connects a callback function to the signal.
	The callback will be invoked whenever the signal is fired.
	
	@param callback (T...) -> () -- The function to call when the signal fires
	@return Connection -- A connection object that can be used to disconnect
]=]
function Signal:Connect<T...>(callback: (T...) -> ()): Connection
	local self = self :: SignalInternal<T...>
	
	local connection: Connection = {
		Connected = true,
		Disconnect = function(conn: Connection)
			if not conn.Connected then
				return
			end
			
			conn.Connected = false
			
			-- Remove from connections list
			local connections = self._connections
			for i = #connections, 1, -1 do
				if connections[i] == conn then
					table.remove(connections, i)
					break
				end
			end
		end,
	}
	
	-- Store callback on connection for firing
	(connection :: any)._callback = callback
	
	table.insert(self._connections, connection)
	
	return connection
end

--[=[
	Yields the current thread until the signal is fired.
	Returns the arguments passed to Fire().
	
	@return T... -- The arguments passed to Fire()
]=]
function Signal:Wait<T...>(): T...
	local self = self :: SignalInternal<T...>
	
	-- Create bindableEvent for waiting if it doesn't exist
	if not self._bindableEvent then
		self._bindableEvent = Instance.new("BindableEvent")
	end
	
	return self._bindableEvent.Event:Wait()
end

--[=[
	Fires the signal, invoking all connected callbacks.
	
	@param ... T... -- Arguments to pass to connected callbacks
]=]
function Signal:Fire<T...>(...: T...)
	local self = self :: SignalInternal<T...>
	
	-- Fire all connections
	local connections = self._connections
	for i = 1, #connections do
		local connection = connections[i]
		if connection.Connected then
			local callback = (connection :: any)._callback
			task.spawn(callback, ...)
		end
	end
	
	-- Fire bindableEvent for Wait()
	if self._bindableEvent then
		self._bindableEvent:Fire(...)
	end
end

--[=[
	Disconnects all connections to this signal.
]=]
function Signal:DisconnectAll<T...>()
	local self = self :: SignalInternal<T...>
	
	local connections = self._connections
	for i = #connections, 1, -1 do
		connections[i]:Disconnect()
	end
end

--[=[
	Destroys the signal, disconnecting all connections and cleaning up resources.
	The signal should not be used after calling this method.
]=]
function Signal:Destroy<T...>()
	local self = self :: SignalInternal<T...>
	
	self:DisconnectAll()
	
	if self._bindableEvent then
		self._bindableEvent:Destroy()
		self._bindableEvent = nil
	end
	
	table.clear(self)
	setmetatable(self, nil)
end

return Signal
