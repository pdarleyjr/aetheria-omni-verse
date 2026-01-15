--!strict
-- Simplified ProfileService for Development/Testing
-- In production, replace this with the actual ProfileService module

local ProfileService = {}
ProfileService.__index = ProfileService

type Profile = {
	Data: any,
	Release: (self: Profile) -> (),
	ListenToRelease: (self: Profile, callback: () -> ()) -> (),
	AddUserId: (self: Profile, userId: number) -> (),
	Reconcile: (self: Profile) -> (),
	IsActive: (self: Profile) -> boolean,
}

local MockStore = {}
MockStore.__index = MockStore

function ProfileService.GetProfileStore(storeName: string, template: any)
	local self = setmetatable({}, MockStore)
	self._template = template
	self._storeName = storeName
	return self
end

function MockStore:LoadProfileAsync(profileKey: string, notReleasedHandler: string | (placeId: number, gameJobId: string) -> string)
	-- Capture template from store instance
	local template = self._template
	
	-- Simulate loading
	local profile = {
		Data = nil,
		_listeners = {},
		_active = true
	}
	
	-- Deep copy template to avoid reference issues
	local function deepCopy(t)
		if type(t) ~= "table" then return t end
		local copy = {}
		for k, v in pairs(t) do
			copy[k] = deepCopy(v)
		end
		return copy
	end
	
	profile.Data = deepCopy(template)

	function profile:Release()
		self._active = false
		for _, callback in ipairs(self._listeners) do
			task.spawn(callback)
		end
	end

	function profile:ListenToRelease(callback)
		table.insert(self._listeners, callback)
		if not self._active then
			task.spawn(callback)
		end
	end

	function profile:AddUserId(userId)
		-- No-op for mock
	end

	function profile:Reconcile()
		-- Simple reconcile using captured template
		if not template then return end
		
		local function reconcileTable(target, source)
			for k, v in pairs(source) do
				if target[k] == nil then
					if type(v) == "table" then
						target[k] = deepCopy(v)
					else
						target[k] = v
					end
				elseif type(target[k]) == "table" and type(v) == "table" then
					reconcileTable(target[k], v)
				end
			end
		end
		
		reconcileTable(profile.Data, template)
	end
	
	function profile:IsActive()
		return self._active
	end

	return profile
end

return ProfileService
