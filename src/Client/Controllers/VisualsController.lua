--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Maid = require(ReplicatedStorage.Shared.Modules.Maid)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

local VisualsController = {}
VisualsController._maid = nil
VisualsController._settings = nil
VisualsController._damageNumberPool = {}
VisualsController._poolSize = 50 -- Expanded from 20 to 50
VisualsController._activeParticles = 0
VisualsController._maxConcurrentParticles = 50

-- LOD distance thresholds
local LOD_SKIP_DISTANCE = 200 -- Skip effects beyond this distance
local LOD_REDUCE_DISTANCE = 100 -- Reduce particle count between 100-200 studs

function VisualsController:Init()
	print("[VisualsController] Initializing...")
	self._maid = Maid.new()
	self._settings = table.clone(Constants.SETTINGS)
	self:CreateDamageNumberPool()
end

function VisualsController:Start()
	print("[VisualsController] Starting...")
	
	self:SetupLighting()
	
	-- Create 3D Guide Arrow pointing toward Glitch Wastes Gate
	self:CreatePathfindingArrow()
	
	local bossAttack = Remotes.GetEvent("BossAttack")
	self._maid:GiveTask(bossAttack.OnClientEvent:Connect(function(attackName, duration)
		if attackName == "Spike" then
			self:ShakeCamera(duration or 0.5, 1)
		end
	end))
	
	-- Listen for ShowDamage
	local ShowDamage = Remotes.GetEvent("ShowDamage")
	if ShowDamage then
		self._maid:GiveTask(ShowDamage.OnClientEvent:Connect(function(targetPart, damage, isCritical, damageType)
			self:ShowDamageNumber(targetPart, damage, isCritical, damageType)
			local intensity = math.clamp(damage / 50, 0.1, 1.0)
			self:ShakeCamera(0.2, isCritical and intensity * 1.5 or intensity * 0.5)
			if targetPart then
				local color = self:GetDamageTypeColor(damageType, isCritical)
				self:PlayBurstParticles(targetPart.Position, color, isCritical and 15 or 8)
			end
		end))
	end
	
	-- Listen for OnCombatHit (combat juice effects)
	local OnCombatHit = Remotes.GetEvent("OnCombatHit")
	if OnCombatHit then
		self._maid:GiveTask(OnCombatHit.OnClientEvent:Connect(function(hitData)
			self:PlayCombatJuice(hitData)
		end))
	end
	
	-- Listen for EnemyDeath (death burst effects)
	local EnemyDeath = Remotes.GetEvent("EnemyDeath")
	if EnemyDeath then
		self._maid:GiveTask(EnemyDeath.OnClientEvent:Connect(function(position, damageType)
			self:PlayDeathBurst(position, damageType)
		end))
	end
	
	-- Listen for EnemyTelegraph (attack telegraphs)
	local EnemyTelegraph = Remotes.GetEvent("EnemyTelegraph")
	if EnemyTelegraph then
		self._maid:GiveTask(EnemyTelegraph.OnClientEvent:Connect(function(position, duration, attackType)
			self:PlayTelegraphIndicator(position, duration, attackType)
		end))
	end
	
	-- Listen for LevelUp
	local LevelUp = Remotes.GetEvent("LevelUp")
	if LevelUp then
		self._maid:GiveTask(LevelUp.OnClientEvent:Connect(function()
			self:PlayLevelUpEffect()
		end))
	end
	
	-- Play Intro
	task.delay(1, function()
		self:PlayIntro()
	end)
	
	-- Monitor for Spirit
	local player = Players.LocalPlayer
	self._maid:GiveTask(player.CharacterAdded:Connect(function(char)
		self:OnCharacterAdded(char)
	end))
	if player.Character then
		self:OnCharacterAdded(player.Character)
	end
end

-- ============================================
-- ACCESSIBILITY SETTINGS
-- ============================================

function VisualsController:SetScreenShakeEnabled(enabled)
	self._settings.ScreenShakeEnabled = enabled
end

function VisualsController:SetFlashEffectsEnabled(enabled)
	self._settings.FlashEffectsEnabled = enabled
end

function VisualsController:SetScreenShakeIntensity(intensity)
	self._settings.ScreenShakeIntensity = math.clamp(intensity, 0, 1)
end

-- ============================================
-- OBJECT POOLING FOR DAMAGE NUMBERS
-- ============================================

function VisualsController:CreateDamageNumberPool()
	self._damageNumberPool = {}
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	
	for i = 1, self._poolSize do
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "PooledDamageNumber_" .. i
		billboard.Size = UDim2.new(0, 150, 0, 75)
		billboard.StudsOffset = Vector3.new(0, 2, 0)
		billboard.AlwaysOnTop = true
		billboard.Enabled = false
		billboard.Parent = playerGui
		
		local label = Instance.new("TextLabel")
		label.Name = "DamageLabel"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = ""
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 18
		label.Parent = billboard
		
		table.insert(self._damageNumberPool, {billboard = billboard, label = label, inUse = false})
	end
end

function VisualsController:GetPooledDamageNumber()
	for _, item in ipairs(self._damageNumberPool) do
		if not item.inUse then
			item.inUse = true
			item.billboard.Enabled = true
			return item
		end
	end
	-- All in use, return first (will reset it)
	local first = self._damageNumberPool[1]
	return first
end

function VisualsController:ReturnToPool(poolItem)
	poolItem.inUse = false
	poolItem.billboard.Enabled = false
	poolItem.billboard.Adornee = nil
end

-- ============================================
-- DAMAGE TYPE COLORS
-- ============================================

function VisualsController:GetDamageTypeColor(damageType, isCritical)
	if isCritical then
		return Constants.DAMAGE_TYPE_COLORS.Critical
	end
	return Constants.DAMAGE_TYPE_COLORS[damageType] or Constants.DAMAGE_TYPE_COLORS.Physical
end

-- ============================================
-- BURST PARTICLE EFFECTS
-- ============================================

function VisualsController:PlayBurstParticles(position, color, count)
	if self._activeParticles >= self._maxConcurrentParticles then return end
	
	-- LOD check: skip effects beyond 200 studs from camera
	local camera = Workspace.CurrentCamera
	if camera then
		local distance = (position - camera.CFrame.Position).Magnitude
		if distance > LOD_SKIP_DISTANCE then
			return -- Skip effect entirely
		elseif distance > LOD_REDUCE_DISTANCE then
			count = math.ceil(count * 0.5) -- Reduce particle count by 50%
		end
	end
	
	self._activeParticles = self._activeParticles + 1
	
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = Workspace
	
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(color)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.Lifetime = NumberRange.new(0.3, 0.5)
	particles.Rate = 0
	particles.Speed = NumberRange.new(15, 25)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Drag = 3
	particles.Parent = part
	particles:Emit(count)
	
	Debris:AddItem(part, 0.6)
	task.delay(0.6, function()
		self._activeParticles = math.max(0, self._activeParticles - 1)
	end)
end

function VisualsController:PlayDeathBurst(position, damageType)
	local color = self:GetDamageTypeColor(damageType, false)
	-- Large burst for death
	self:PlayBurstParticles(position, color, 30)
	
	-- Extra shockwave ring
	local ring = Instance.new("Part")
	ring.Size = Vector3.new(2, 0.1, 2)
	ring.Position = position
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.3
	ring.Shape = Enum.PartType.Cylinder
	ring.Orientation = Vector3.new(0, 0, 90)
	ring.Parent = Workspace
	
	local tween = TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(15, 0.1, 15),
		Transparency = 1
	})
	tween:Play()
	Debris:AddItem(ring, 0.5)
	
	-- Stronger screen shake for deaths
	self:ShakeCamera(0.3, 0.8)
	
	-- Apply hit-stop for death impact
	self:ApplyHitstop(Constants.HITSTOP.DEATH_DURATION)
end

-- ============================================
-- SCREEN SHAKE SYSTEM
-- ============================================

function VisualsController:ShakeCamera(duration, intensity)
	if not self._settings.ScreenShakeEnabled then return end
	
	local adjustedIntensity = intensity * self._settings.ScreenShakeIntensity
	if adjustedIntensity <= 0 then return end
	
	local camera = Workspace.CurrentCamera
	local startTime = os.clock()
	
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed >= duration then
			connection:Disconnect()
			return
		end
		
		-- Intensity curve: quick start, smooth falloff
		local progress = elapsed / duration
		local falloff = 1 - (progress ^ 0.5) -- Square root falloff for snappier feel
		local currentIntensity = adjustedIntensity * falloff
		
		local offset = Vector3.new(
			(math.random() - 0.5) * 2,
			(math.random() - 0.5) * 2,
			(math.random() - 0.5) * 2
		) * currentIntensity
		
		camera.CFrame = camera.CFrame * CFrame.new(offset)
	end)
	
	self._maid:GiveTask(connection)
end

-- ============================================
-- HIT-STOP FRAMES
-- ============================================

function VisualsController:ApplyHitstop(duration)
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	local originalSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = 0
	
	task.delay(duration, function()
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = originalSpeed
		end
	end)
end

-- ============================================
-- FLOATING DAMAGE NUMBERS (POOLED)
-- ============================================

function VisualsController:ShowDamageNumber(targetPart, damage, isCritical, damageType)
	if not self._settings.DamageNumbersEnabled then return end
	if not targetPart then return end
	
	local poolItem = self:GetPooledDamageNumber()
	local billboard = poolItem.billboard
	local label = poolItem.label
	
	-- Configure appearance
	billboard.Adornee = targetPart
	billboard.StudsOffset = Vector3.new(math.random(-1, 1), 2, 0)
	
	local color = self:GetDamageTypeColor(damageType, isCritical)
	label.Text = isCritical and "💥" .. tostring(damage) or "-" .. tostring(damage)
	label.TextColor3 = color
	label.TextSize = isCritical and 28 or 18
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0
	
	-- Reset scale for animation
	if isCritical then
		label.TextSize = 36 -- Start bigger for pop effect
	end
	
	-- Animate float up and fade
	local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local offsetTween = TweenService:Create(billboard, tweenInfo, {
		StudsOffset = billboard.StudsOffset + Vector3.new(0, 3, 0)
	})
	
	local fadeTween = TweenService:Create(label, TweenInfo.new(0.8), {
		TextTransparency = 1,
		TextStrokeTransparency = 1
	})
	
	-- Shrink critical text for pop effect
	if isCritical then
		local sizeTween = TweenService:Create(label, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = 28
		})
		sizeTween:Play()
	end
	
	offsetTween:Play()
	fadeTween:Play()
	
	task.delay(0.8, function()
		self:ReturnToPool(poolItem)
	end)
end

-- ============================================
-- COMBAT JUICE ORCHESTRATION
-- ============================================

function VisualsController:PlayCombatJuice(hitData)
	local damage = hitData.damage or 0
	local isCritical = hitData.isCritical
	local hitPosition = hitData.hitPosition
	local damageType = hitData.damageType or "Physical"
	
	-- Hit-stop effect (brief pause)
	local hitstopDuration = isCritical and Constants.HITSTOP.CRITICAL_DURATION or Constants.HITSTOP.NORMAL_DURATION
	self:ApplyHitstop(hitstopDuration)
	
	-- Enhanced critical hit visual
	if isCritical then
		self:PlayCriticalHitEffect(hitPosition)
	end
	
	-- Weapon swing trail (on local player)
	local player = Players.LocalPlayer
	local character = player.Character
	if character then
		self:PlayWeaponSwingTrail(character)
	end
end

function VisualsController:PlayWeaponSwingTrail(character)
	local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
	if not rightArm then return end
	
	local att0 = Instance.new("Attachment")
	att0.Position = Vector3.new(0, 0.5, 0)
	att0.Parent = rightArm
	
	local att1 = Instance.new("Attachment")
	att1.Position = Vector3.new(0, -0.5, 0)
	att1.Parent = rightArm
	
	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Lifetime = 0.2
	trail.MinLength = 0.1
	trail.FaceCamera = true
	trail.Parent = rightArm
	
	Debris:AddItem(att0, 0.3)
	Debris:AddItem(att1, 0.3)
	Debris:AddItem(trail, 0.3)
end

function VisualsController:PlayCriticalHitEffect(position)
	if not position then return end
	
	local part = Instance.new("Part")
	part.Size = Vector3.new(2, 2, 2)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = Constants.DAMAGE_TYPE_COLORS.Critical
	part.Transparency = 0
	part.Shape = Enum.PartType.Ball
	part.Parent = Workspace
	
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Constants.DAMAGE_TYPE_COLORS.Critical)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Lifetime = NumberRange.new(0.3, 0.5)
	particles.Rate = 0
	particles.Speed = NumberRange.new(20, 40)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Parent = part
	particles:Emit(20)
	
	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(part, tweenInfo, {
		Size = Vector3.new(8, 8, 8),
		Transparency = 1
	})
	tween:Play()
	
	Debris:AddItem(part, 0.5)
	
	if self._settings.FlashEffectsEnabled then
		self:FlashScreen(Constants.DAMAGE_TYPE_COLORS.Critical, 0.1)
	end
end

function VisualsController:FlashScreen(color, duration)
	if not self._settings.FlashEffectsEnabled then return end
	
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return end
	
	local flash = Instance.new("ScreenGui")
	flash.Name = "CritFlash"
	flash.IgnoreGuiInset = true
	flash.Parent = playerGui
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.7
	frame.BorderSizePixel = 0
	frame.Parent = flash
	
	local tween = TweenService:Create(frame, TweenInfo.new(duration), {BackgroundTransparency = 1})
	tween:Play()
	
	Debris:AddItem(flash, duration)
end

-- ============================================
-- EXISTING METHODS (updated)
-- ============================================

function VisualsController:OnCharacterAdded(char)
	char.ChildAdded:Connect(function(child)
		if child.Name == "ActiveSpirit" then
			self:LinkSpiritToPlayer(char, child)
		end
	end)
	
	local existingSpirit = char:FindFirstChild("ActiveSpirit")
	if existingSpirit then
		self:LinkSpiritToPlayer(char, existingSpirit)
	end
end

function VisualsController:LinkSpiritToPlayer(char, spirit)
	local root = char:WaitForChild("HumanoidRootPart", 5)
	if not root then return end
	
	local att0 = Instance.new("Attachment")
	att0.Name = "SpiritAtt0"
	att0.Position = Vector3.new(0, 0, 0)
	att0.Parent = root
	
	local att1 = Instance.new("Attachment")
	att1.Name = "SpiritAtt1"
	att1.Position = Vector3.new(0, 0, 0)
	att1.Parent = spirit
	
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(spirit.Color)
	beam.FaceCamera = true
	beam.Width0 = 0.2
	beam.Width1 = 0.2
	beam.Texture = "rbxassetid://446111271"
	beam.TextureSpeed = 1
	beam.Transparency = NumberSequence.new(0.5)
	beam.Parent = spirit
end

function VisualsController:PlayBeamAttack(origin, target, color)
	local terrain = Workspace.Terrain
	
	local att0 = Instance.new("Attachment")
	att0.WorldPosition = origin
	att0.Parent = terrain
	
	local att1 = Instance.new("Attachment")
	att1.WorldPosition = target
	att1.Parent = terrain
	
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(color or Color3.new(1, 1, 1))
	beam.Width0 = 0.5
	beam.Width1 = 0.5
	beam.FaceCamera = true
	beam.Texture = "rbxassetid://446111271"
	beam.TextureSpeed = 2
	beam.TextureLength = 1
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Parent = terrain
	
	Debris:AddItem(att0, 0.5)
	Debris:AddItem(att1, 0.5)
	Debris:AddItem(beam, 0.5)
	
	local tween = TweenService:Create(beam, TweenInfo.new(0.5), {Width0 = 0, Width1 = 0})
	tween:Play()
end

function VisualsController:SetupLighting()
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(30, 30, 40)
	lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 60)
	lighting.Brightness = 2
	lighting.ClockTime = 18
	lighting.GlobalShadows = true
	
	if not lighting:FindFirstChild("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.3
		atmosphere.Offset = 0.25
		atmosphere.Color = Color3.fromRGB(199, 170, 199)
		atmosphere.Decay = Color3.fromRGB(106, 90, 106)
		atmosphere.Glare = 0
		atmosphere.Haze = 1
		atmosphere.Parent = lighting
	end
	
	if not lighting:FindFirstChild("Bloom") then
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "Bloom"
		bloom.Intensity = 0.4
		bloom.Size = 24
		bloom.Threshold = 0.8
		bloom.Parent = lighting
	end
	
	if not lighting:FindFirstChild("SunRays") then
		local sunrays = Instance.new("SunRaysEffect")
		sunrays.Name = "SunRays"
		sunrays.Intensity = 0.05
		sunrays.Parent = lighting
	end
end

function VisualsController:PlayIntro()
	local camera = Workspace.CurrentCamera
	local player = Players.LocalPlayer
	
	local character = player.Character
	if not character then
		character = player.CharacterAdded:Wait()
	end
	
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if not rootPart then return end
	
	camera.CameraType = Enum.CameraType.Scriptable
	
	local startCFrame = CFrame.new(rootPart.Position + Vector3.new(100, 150, 100), rootPart.Position)
	camera.CFrame = startCFrame
	
	local blur = Instance.new("BlurEffect")
	blur.Size = 24
	blur.Parent = camera
	
	local tweenInfo1 = TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local goal1 = { CFrame = CFrame.new(rootPart.Position + Vector3.new(-50, 80, 50), rootPart.Position) }
	local tween1 = TweenService:Create(camera, tweenInfo1, goal1)
	
	local tweenInfo2 = TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal2 = { CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 10, 15), Vector3.new(0, 5, 0)) }
	local tween2 = TweenService:Create(camera, tweenInfo2, goal2)
	
	tween1:Play()
	
	tween1.Completed:Connect(function()
		tween2:Play()
		TweenService:Create(blur, TweenInfo.new(4, Enum.EasingStyle.Linear), {Size = 0}):Play()
	end)
	
	tween2.Completed:Connect(function()
		camera.CameraType = Enum.CameraType.Custom
		blur:Destroy()
		self:ShowWelcomeText()
	end)
end

function VisualsController:ShowWelcomeText()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IntroGui"
	screenGui.Parent = playerGui
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 100)
	label.Position = UDim2.new(0, 0, 0.4, 0)
	label.BackgroundTransparency = 1
	label.Text = "WELCOME TO THE HUB. DEFEAT THE GLITCH."
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 48
	label.TextTransparency = 1
	label.Parent = screenGui
	
	local t1 = TweenService:Create(label, TweenInfo.new(1), {TextTransparency = 0})
	t1:Play()
	
	t1.Completed:Connect(function()
		task.wait(2)
		local t2 = TweenService:Create(label, TweenInfo.new(1), {TextTransparency = 1})
		t2:Play()
		t2.Completed:Connect(function()
			screenGui:Destroy()
		end)
	end)
end

function VisualsController:PlayLevelUpEffect()
	local player = Players.LocalPlayer
	local char = player.Character
	if not char then return end
	
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local part = Instance.new("Part")
	part.Size = Vector3.new(5, 1, 5)
	part.CFrame = root.CFrame * CFrame.new(0, -2, 0)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 215, 0)
	part.Transparency = 0.5
	part.Shape = Enum.PartType.Cylinder
	part.Parent = Workspace
	
	local tween = TweenService:Create(part, TweenInfo.new(1), {
		Size = Vector3.new(5, 20, 5),
		Transparency = 1,
		CFrame = root.CFrame * CFrame.new(0, 10, 0)
	})
	tween:Play()
	Debris:AddItem(part, 1)
end

function VisualsController:PlayHitEffect(position: Vector3, color: Color3?)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = color or Color3.fromRGB(255, 255, 255)
	part.Transparency = 0.2
	part.Shape = Enum.PartType.Ball
	part.Parent = Workspace
	
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {
		Size = Vector3.new(3, 3, 3),
		Transparency = 1
	}
	
	local tween = TweenService:Create(part, tweenInfo, goal)
	tween:Play()
	
	Debris:AddItem(part, 0.3)
end

function VisualsController:PlayAttackEffect(origin: Vector3, target: Vector3, color: Color3?)
	local distance = (target - origin).Magnitude
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.5, 0.5, distance)
	part.CFrame = CFrame.lookAt(origin, target) * CFrame.new(0, 0, -distance/2)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = color or Color3.fromRGB(255, 255, 100)
	part.Parent = Workspace
	
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {
		Size = Vector3.new(0, 0, distance),
		Transparency = 1
	}
	
	local tween = TweenService:Create(part, tweenInfo, goal)
	tween:Play()
	
	Debris:AddItem(part, 0.2)
end

function VisualsController:PlayTelegraphIndicator(position: Vector3, duration: number, attackType: string?)
	local color = Color3.fromRGB(255, 100, 100)
	local size = 6
	
	if attackType == "slam" then
		size = 10
		color = Color3.fromRGB(255, 50, 50)
	elseif attackType == "swipe" then
		size = 8
		color = Color3.fromRGB(255, 150, 50)
	elseif attackType == "projectile" then
		size = 4
		color = Color3.fromRGB(255, 200, 50)
	end
	
	local indicator = Instance.new("Part")
	indicator.Name = "TelegraphIndicator"
	indicator.Size = Vector3.new(size, 0.1, size)
	indicator.Position = position + Vector3.new(0, 0.05, 0)
	indicator.Anchored = true
	indicator.CanCollide = false
	indicator.Material = Enum.Material.Neon
	indicator.Color = color
	indicator.Transparency = 0.7
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Orientation = Vector3.new(0, 0, 90)
	indicator.Parent = Workspace
	
	local inner = Instance.new("Part")
	inner.Name = "TelegraphInner"
	inner.Size = Vector3.new(0, 0.15, 0)
	inner.Position = position + Vector3.new(0, 0.1, 0)
	inner.Anchored = true
	inner.CanCollide = false
	inner.Material = Enum.Material.Neon
	inner.Color = Color3.fromRGB(255, 255, 255)
	inner.Transparency = 0.3
	inner.Shape = Enum.PartType.Cylinder
	inner.Orientation = Vector3.new(0, 0, 90)
	inner.Parent = Workspace
	
	local fillTween = TweenService:Create(inner, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = Vector3.new(size, 0.15, size),
		Transparency = 0.5
	})
	fillTween:Play()
	
	local pulseCount = math.floor(duration / 0.3)
	for i = 1, pulseCount do
		task.delay(i * 0.3, function()
			if indicator and indicator.Parent then
				local pulse = TweenService:Create(indicator, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
					Transparency = 0.4
				})
				pulse:Play()
			end
		end)
	end
	
	Debris:AddItem(indicator, duration + 0.1)
	Debris:AddItem(inner, duration + 0.1)
end

function VisualsController:CreatePathfindingArrow()
	local player = Players.LocalPlayer
	
	-- Create red neon cone arrow
	local arrow = Instance.new("Part")
	arrow.Name = "PathfindingArrow"
	arrow.Size = Vector3.new(4, 8, 4)
	arrow.Shape = Enum.PartType.Ball -- Using ball as base, we'll make it cone-like with mesh
	arrow.Material = Enum.Material.Neon
	arrow.BrickColor = BrickColor.new("Bright red")
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.CastShadow = false
	arrow.Transparency = 0.3
	arrow.Parent = Workspace
	
	-- Add a cone mesh to make it arrow-shaped
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Cylinder
	mesh.Scale = Vector3.new(0.5, 2, 0.5)
	mesh.Parent = arrow
	
	-- Add glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(255, 50, 50)
	pointLight.Brightness = 2
	pointLight.Range = 15
	pointLight.Parent = arrow
	
	-- Target position: Glitch Wastes Gate
	local targetPos = Vector3.new(0, 5, 200)
	
	-- Update arrow position and rotation every frame
	local heartbeatConnection = RunService.Heartbeat:Connect(function()
		local character = player.Character
		if not character then return end
		
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		
		-- Position 15 studs above player
		local arrowPos = root.Position + Vector3.new(0, 15, 0)
		
		-- Calculate direction to target
		local direction = (targetPos - arrowPos).Unit
		
		-- Use CFrame.lookAt and rotate to point downward like an arrow
		local lookCFrame = CFrame.lookAt(arrowPos, arrowPos + direction)
		-- Rotate 90 degrees on X axis so cylinder points forward
		arrow.CFrame = lookCFrame * CFrame.Angles(math.rad(90), 0, 0)
	end)
	
	self._maid:GiveTask(heartbeatConnection)
	self._maid:GiveTask(arrow)
	
	self.PathfindingArrow = arrow
	print("[VisualsController] Created Pathfinding Arrow pointing toward Glitch Wastes Gate")
end

return VisualsController
