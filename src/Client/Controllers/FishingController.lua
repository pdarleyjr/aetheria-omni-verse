local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local FishingController = Knit.CreateController {
	Name = "FishingController",
}

-- Minigame Constants
local BAR_HEIGHT = 300
local BAR_WIDTH = 30
local TARGET_SIZE = 80
local PLAYER_BAR_SIZE = 40
local GRAVITY = 600
local LIFT_FORCE = 1200
local CATCH_SPEED = 25 -- % per second
local DECAY_SPEED = 10 -- % per second

function FishingController:KnitStart()
	self.FishingService = Knit.GetService("FishingService")
	
	-- Input to start fishing (e.g., 'F' key)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.F then
			self:AttemptStartFishing()
		end
	end)
end

function FishingController:AttemptStartFishing()
	if self.IsFishing then return end
	
	-- In a real game, check if player is near water or has a rod equipped
	-- For this phase, we assume valid conditions if they press F
	
	self.FishingService:StartFishing():andThen(function(sessionData)
		if sessionData then
			self.IsFishing = true
			self:StartMinigame(sessionData)
		end
	end):catch(warn)
end

function FishingController:StartMinigame(sessionData)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Create UI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FishingMinigame"
	screenGui.Parent = playerGui
	
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(0, BAR_WIDTH, 0, BAR_HEIGHT)
	bg.Position = UDim2.new(0.5, -BAR_WIDTH/2, 0.5, -BAR_HEIGHT/2)
	bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	bg.BorderSizePixel = 2
	bg.BorderColor3 = Color3.fromRGB(200, 200, 200)
	bg.Parent = screenGui
	
	local target = Instance.new("Frame")
	target.Name = "TargetZone"
	target.Size = UDim2.new(1, 0, 0, TARGET_SIZE)
	target.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	target.BackgroundTransparency = 0.6
	target.BorderSizePixel = 0
	target.Parent = bg
	
	local playerBar = Instance.new("Frame")
	playerBar.Name = "PlayerBar"
	playerBar.Size = UDim2.new(1, -4, 0, PLAYER_BAR_SIZE)
	playerBar.Position = UDim2.new(0, 2, 0, 0)
	playerBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
	playerBar.BorderSizePixel = 0
	playerBar.Parent = bg
	
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(0, 10, 1, 0)
	progressBg.Position = UDim2.new(1, 5, 0, 0)
	progressBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	progressBg.Parent = bg
	
	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(1, 0, 0, 0)
	progressBar.Position = UDim2.new(0, 0, 1, 0)
	progressBar.AnchorPoint = Vector2.new(0, 1)
	progressBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBg
	
	-- Game State
	local progress = 0
	local playerPos = 0 -- 0 (bottom) to MaxHeight
	local playerVelocity = 0
	local targetPos = 0
	local targetDirection = 1
	local targetSpeed = 100 * (sessionData.Difficulty or 1)
	
	local maxHeight = BAR_HEIGHT - PLAYER_BAR_SIZE
	local targetMaxHeight = BAR_HEIGHT - TARGET_SIZE
	
	local connection
	
	local function Cleanup()
		if connection then connection:Disconnect() end
		if screenGui then screenGui:Destroy() end
		self.IsFishing = false
	end
	
	connection = RunService.RenderStepped:Connect(function(dt)
		-- 1. Player Physics
		local holding = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) 
						or UserInputService:IsKeyDown(Enum.KeyCode.Space)
		
		if holding then
			playerVelocity = playerVelocity + (LIFT_FORCE * dt)
		else
			playerVelocity = playerVelocity - (GRAVITY * dt)
		end
		
		playerPos = playerPos + (playerVelocity * dt)
		
		-- Bounce/Clamp Player
		if playerPos < 0 then
			playerPos = 0
			playerVelocity = 0 -- Stop at bottom
		elseif playerPos > maxHeight then
			playerPos = maxHeight
			playerVelocity = 0 -- Stop at top
		end
		
		-- 2. Target Movement
		targetPos = targetPos + (targetSpeed * targetDirection * dt)
		
		-- Change direction randomly or at bounds
		if targetPos < 0 or targetPos > targetMaxHeight then
			targetDirection = -targetDirection
			targetPos = math.clamp(targetPos, 0, targetMaxHeight)
			
			-- Randomize speed slightly
			targetSpeed = (100 * (sessionData.Difficulty or 1)) * (0.8 + math.random() * 0.4)
		end
		
		-- 3. Update Visuals
		-- Y position needs to be inverted for UDim2 (0 is top)
		-- We want playerPos 0 to be at the bottom (Y = BAR_HEIGHT - PLAYER_BAR_SIZE)
		playerBar.Position = UDim2.new(0, 2, 0, BAR_HEIGHT - playerPos - PLAYER_BAR_SIZE)
		target.Position = UDim2.new(0, 0, 0, BAR_HEIGHT - targetPos - TARGET_SIZE)
		
		-- 4. Check Overlap
		-- Overlap if the player bar is mostly inside the target
		-- Let's use simple intersection
		local playerBottom = playerPos
		local playerTop = playerPos + PLAYER_BAR_SIZE
		local targetBottom = targetPos
		local targetTop = targetPos + TARGET_SIZE
		
		local isInside = (playerBottom >= targetBottom) and (playerTop <= targetTop)
		-- Or just overlapping? "Keep the Player Bar inside the Target Zone" implies containment.
		-- Let's be slightly lenient: Center point check?
		local playerCenter = playerPos + PLAYER_BAR_SIZE/2
		local targetCenter = targetPos + TARGET_SIZE/2
		local dist = math.abs(playerCenter - targetCenter)
		local threshold = (TARGET_SIZE / 2) -- If center is within target bounds
		
		if dist < threshold then
			progress = progress + (CATCH_SPEED * dt)
			progressBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		else
			progress = progress - (DECAY_SPEED * dt)
			progressBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		end
		
		progress = math.clamp(progress, 0, 100)
		progressBar.Size = UDim2.new(1, 0, progress/100, 0)
		
		-- 5. Win/Loss
		if progress >= 100 then
			Cleanup()
			self.FishingService:ProcessCatch(true):andThen(function(success, fishName)
				if success then
					print("Caught a " .. tostring(fishName) .. "!")
				end
			end)
		end
		
		-- Optional: Fail condition if progress hits 0 after starting?
	end)
end

function FishingController:KnitInit()
	
end

return FishingController
