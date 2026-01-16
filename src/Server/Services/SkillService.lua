--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local SkillService = {}
local Cooldowns = {} -- [Player][SkillName] = os.time()

function SkillService:Init()
	print("[SkillService] Init")
	self.RequestSkillRemote = Remotes.GetEvent("RequestSkill")
	
	self.RequestSkillRemote.OnServerEvent:Connect(function(player, skillName, targetPosition)
		self:HandleSkillRequest(player, skillName, targetPosition)
	end)
end

function SkillService:Start()
	print("[SkillService] Start")
end

function SkillService:HandleSkillRequest(player, skillName, targetPosition)
	local skillData = Constants.SKILLS[skillName]
	if not skillData then return end
	
	-- Cooldown Check
	if not Cooldowns[player] then Cooldowns[player] = {} end
	local lastUse = Cooldowns[player][skillName] or 0
	if os.time() - lastUse < skillData.Cooldown then
		return -- On cooldown
	end
	
	-- Cost Check
	if not DataService.RemoveCurrency(player, "Essence", skillData.Cost) then
		return -- Not enough currency
	end
	
	-- Apply Cooldown
	Cooldowns[player][skillName] = os.time()
	
	-- Execute Skill
	if skillName == "Fireball" then
		self:CastFireball(player, targetPosition)
	elseif skillName == "Dash" then
		self:CastDash(player)
	end
end

function SkillService:CastFireball(player, targetPosition)
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local startPos = rootPart.Position + (rootPart.CFrame.LookVector * 5)
	local direction = (targetPosition - startPos).Unit
	
	local fireball = Instance.new("Part")
	fireball.Name = "Fireball"
	fireball.Shape = Enum.PartType.Ball
	fireball.Size = Vector3.new(2, 2, 2)
	fireball.Position = startPos
	fireball.Color = Color3.fromRGB(255, 100, 0)
	fireball.Material = Enum.Material.Neon
	fireball.CanCollide = false
	fireball.Parent = workspace
	
	-- Physics
	local attachment = Instance.new("Attachment", fireball)
	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = direction * Constants.SKILLS.Fireball.Speed
	velocity.Parent = fireball
	
	-- Anti-Gravity
	local force = Instance.new("VectorForce")
	force.Attachment0 = attachment
	force.Force = Vector3.new(0, fireball:GetMass() * workspace.Gravity, 0)
	force.Parent = fireball
	
	-- Hit Detection
	local touchedConn
	touchedConn = fireball.Touched:Connect(function(hit)
		if hit:IsDescendantOf(character) then return end
		
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:TakeDamage(Constants.SKILLS.Fireball.Damage)
			-- Visual explosion could be spawned here
		end
		if touchedConn then touchedConn:Disconnect() end
		fireball:Destroy()
	end)
	
	Debris:AddItem(fireball, 3)
end

function SkillService:CastDash(player)
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local attachment = Instance.new("Attachment", rootPart)
	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = rootPart.CFrame.LookVector * 100 -- Dash speed
	velocity.Parent = rootPart
	
	Debris:AddItem(velocity, 0.2) -- Dash duration
	Debris:AddItem(attachment, 0.2)
end

return SkillService
