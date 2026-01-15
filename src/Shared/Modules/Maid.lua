--!strict

--[[
	Maid.lua
	
	A memory management utility for automatic cleanup of resources.
	Prevents memory leaks by tracking and cleaning up connections, instances, and functions.
	
	Usage:
		local maid = Maid.new()
		
		-- Track a connection
		maid:GiveTask(workspace.Part.Touched:Connect(function()
			print("Touched!")
		end))
		
		-- Track an instance
		local part = Instance.new("Part")
		maid:GiveTask(part)
		
		-- Track a cleanup function
		maid:GiveTask(function()
			print("Cleaning up!")
		end)
		
		-- Track another maid
		local subMaid = Maid.new()
		maid:GiveTask(subMaid)
		
		-- Clean up everything
		maid:DoCleaning()
		
		-- Or destroy (same as DoCleaning but prevents reuse)
		maid:Destroy()
	
	@class Maid
]]

export type Maid = {
	GiveTask: (self: Maid, task: Task) -> (),
	DoCleaning: (self: Maid) -> (),
	Destroy: (self: Maid) -> (),
}

-- Task can be a connection, instance, function, or another maid
type Task = RBXScriptConnection | Instance | (() -> ()) | Maid

type MaidInternal = Maid & {
	_tasks: { Task },
	_cleaning: boolean,
}

local Maid = {}
Maid.__index = Maid

--[=[
	Creates a new Maid instance.
	
	@return Maid -- The new maid
]=]
function Maid.new(): Maid
	local self = setmetatable({
		_tasks = {},
		_cleaning = false,
	}, Maid) :: any
	
	return self :: Maid
end

--[=[
	Adds a task to be cleaned up later.
	Supports:
	- RBXScriptConnection (will call :Disconnect())
	- Instance (will call :Destroy())
	- Function (will be called)
	- Maid (will call :Destroy())
	
	@param task Task -- The task to track
]=]
function Maid:GiveTask(task: Task)
	local self = self :: MaidInternal
	
	if self._cleaning then
		warn("Maid:GiveTask() called during cleanup - task will be immediately cleaned")
		Maid._cleanTask(task)
		return
	end
	
	table.insert(self._tasks, task)
end

--[=[
	Private helper to clean a single task based on its type.
	
	@param task Task -- The task to clean
	@private
]=]
function Maid._cleanTask(task: Task)
	local taskType = typeof(task)
	
	if taskType == "RBXScriptConnection" then
		-- Disconnect connection
		(task :: RBXScriptConnection):Disconnect()
		
	elseif taskType == "Instance" then
		-- Destroy instance
		(task :: Instance):Destroy()
		
	elseif taskType == "function" then
		-- Call cleanup function
		(task :: () -> ())()
		
	elseif taskType == "table" then
		-- Check if it's a maid or has a Destroy method
		local taskTable = task :: any
		if taskTable.Destroy and type(taskTable.Destroy) == "function" then
			taskTable:Destroy()
		else
			warn("Maid:GiveTask() received a table without a Destroy method")
		end
	else
		warn(`Maid:GiveTask() received unsupported task type: {taskType}`)
	end
end

--[=[
	Cleans up all tracked tasks.
	Tasks are cleaned in reverse order (LIFO).
	The maid can be reused after calling this method.
]=]
function Maid:DoCleaning()
	local self = self :: MaidInternal
	
	if self._cleaning then
		return
	end
	
	self._cleaning = true
	
	local tasks = self._tasks
	
	-- Clean in reverse order (LIFO)
	for i = #tasks, 1, -1 do
		local task = tasks[i]
		tasks[i] = nil
		
		-- Clean task with error handling
		local success, err = pcall(Maid._cleanTask, task)
		if not success then
			warn(`Maid cleanup error: {err}`)
		end
	end
	
	self._cleaning = false
end

--[=[
	Destroys the maid, cleaning up all tasks and preventing future use.
	This is equivalent to calling DoCleaning() and then clearing the maid.
]=]
function Maid:Destroy()
	local self = self :: MaidInternal
	
	self:DoCleaning()
	
	table.clear(self)
	setmetatable(self, nil)
end

return Maid
