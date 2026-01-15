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
	-- Simulate loading
	local profile = {
		Data = table.clone(self._template),
		_listeners = {},
		_active = true
	}
	
	-- Deep copy template to avoid reference issues
	local function deepCopy(t)
		local copy = {}
		for k, v in pairs(t) do
			if type(v) == "table" then
				copy[k] = deepCopy(v)
			else
				copy[k] = v
			end
		end
		return copy
	end
	profile.Data = deepCopy(self._template)

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
		-- Simple reconcile
		for k, v in pairs(self._template) do
			if profile.Data[k] == nil then
				profile.Data[k] = v
			end
		end
	end
	
	function profile:IsActive()
		return self._active
	end

	return profile
end

return ProfileService
