--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local QuestService = {}
QuestService.ActiveQuests = {} -- [playerId] = { QuestId = "Tutorial", Progress = { ... } }

-- Quest Definitions
local QUESTS = {
	["WelcomeQuest"] = {
		Title = "Welcome to Aetheria",
		Description = "The world is glitching. Prepare yourself.",
		Tasks = {
			{
				Id = "explore_hub",
				Type = "Visit",
				Target = "Hub",
				Required = 1,
				Description = "Explore the Hub"
			}
		},
		Rewards = {
			Exp = 50,
			Currencies = { Essence = 50 },
			Items = {}
		}
	},
	["Tutorial"] = {
		Title = "First Steps",
		Description = "Welcome to the Realm. Follow the guide's instructions.",
		Tasks = {
			{
				Id = "talk_guide",
				Type = "Talk",
				Target = "Guide",
				Required = 1,
				Description = "Talk to the Guide"
			},
			{
				Id = "kill_slimes",
				Type = "Kill",
				Target = "Glitch Slime",
				Required = 3,
				Description = "Defeat 3 Glitch Slimes"
			},
			{
				Id = "visit_sea",
				Type = "Visit",
				Target = "Azure Sea",
				Required = 1,
				Description = "Visit the Azure Sea"
			}
		},
		Rewards = {
			Exp = 100,
			Currencies = { Essence = 100 },
			Items = { { Id = "Starter Rod", Amount = 1 } }
		}
	}
}

function QuestService:Init()
	print("[QuestService] Initializing...")
	
	-- Create Remotes if they don't exist (handled by Remotes module usually, but we might need to register)
	-- Assuming Remotes.lua handles dynamic creation or we use existing ones.
	-- We'll use a generic "QuestUpdate" event.
end

function QuestService:Start()
	print("[QuestService] Starting...")
	
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)
	
	-- Listen for enemy deaths (This should be connected via Signal or direct call from EnemyService)
	-- For now, we'll expose a method that EnemyService calls.
end

function QuestService:OnPlayerAdded(player: Player)
	-- Load data, check if tutorial is done
	-- For now, we always assign the tutorial if not active
	
	task.wait(2) -- Wait for client to load
	self:AssignQuest(player, "WelcomeQuest")
	
	-- Auto-complete first step for now
	-- self:ProgressTask(player, "talk_guide", 1)
end

function QuestService:AssignQuest(player: Player, questId: string)
	local questDef = QUESTS[questId]
	if not questDef then return end
	
	local questData = {
		Id = questId,
		Tasks = {}
	}
	
	for _, taskDef in ipairs(questDef.Tasks) do
		questData.Tasks[taskDef.Id] = {
			Current = 0,
			Required = taskDef.Required
		}
	end
	
	self.ActiveQuests[player.UserId] = questData
	
	self:UpdateClient(player)
	print("[QuestService] Assigned quest " .. questId .. " to " .. player.Name)
end

function QuestService:OnEnemyKilled(player: Player, enemyName: string)
	-- Auto-complete first step for now
	self:CheckTaskProgress(player, "Kill", enemyName)
end

function QuestService:OnZoneEntered(player: Player, zoneName: string)
	-- Auto-complete first step for now
	self:CheckTaskProgress(player, "Visit", zoneName)
end

function QuestService:ProgressTask(player: Player, taskId: string, amount: number)
	local activeQuest = self.ActiveQuests[player.UserId]
	if not activeQuest then return end
	
	local questDef = QUESTS[activeQuest.Id]
	if not questDef then return end
	
	local taskData = activeQuest.Tasks[taskId]
	if not taskData then return end
	
	if taskData.Current < taskData.Required then
		taskData.Current = math.min(taskData.Current + amount, taskData.Required)
		self:UpdateClient(player)
		self:CheckCompletion(player)
	end
end

function QuestService:CheckTaskProgress(player: Player, type: string, target: string)
	local activeQuest = self.ActiveQuests[player.UserId]
	if not activeQuest then return end
	
	local questDef = QUESTS[activeQuest.Id]
	
	for _, taskDef in ipairs(questDef.Tasks) do
		if taskDef.Type == type and taskDef.Target == target then
			self:ProgressTask(player, taskDef.Id, 1)
		end
	end
end

function QuestService:CheckCompletion(player: Player)
	local activeQuest = self.ActiveQuests[player.UserId]
	if not activeQuest then return false end
	
	local questDef = QUESTS[activeQuest.Id]
	local allComplete = true
	
	for _, taskDef in ipairs(questDef.Tasks) do
		local taskData = activeQuest.Tasks[taskDef.Id]
		if taskData.Current < taskData.Required then
			allComplete = false
			break
		end
	end
	
	if allComplete then
		self:CompleteQuest(player)
		return true
	end
	
	return false
end

function QuestService:CompleteQuest(player: Player)
	local activeQuest = self.ActiveQuests[player.UserId]
	if not activeQuest then return end
	
	local questDef = QUESTS[activeQuest.Id]
	
	print("[QuestService] " .. player.Name .. " completed quest " .. activeQuest.Id)
	
	-- Give Rewards
	if questDef.Rewards.Exp then
		-- SpiritService:AddExp(player, questDef.Rewards.Exp) -- Need to require SpiritService or use Signal
	end
	
	-- TODO: Give Items and Currency via DataService
	
	self.ActiveQuests[player.UserId] = nil
	
	-- Notify Client of completion (maybe pass nil or a "Completed" status)
	local QuestUpdate = Remotes.GetEvent("QuestUpdate")
	QuestUpdate:FireClient(player, nil) -- Clear quest tracker
end

function QuestService:UpdateClient(player: Player)
	local activeQuest = self.ActiveQuests[player.UserId]
	local QuestUpdate = Remotes.GetEvent("QuestUpdate")
	
	if activeQuest then
		local questDef = QUESTS[activeQuest.Id]
		-- Send a simplified structure for UI
		local uiData = {
			Title = questDef.Title,
			Description = questDef.Description,
			Tasks = {}
		}
		
		for _, taskDef in ipairs(questDef.Tasks) do
			local taskData = activeQuest.Tasks[taskDef.Id]
			table.insert(uiData.Tasks, {
				Description = taskDef.Description,
				Current = taskData.Current,
				Required = taskData.Required
			})
		end
		
		QuestUpdate:FireClient(player, uiData)
	else
		QuestUpdate:FireClient(player, nil)
	end
end

return QuestService
