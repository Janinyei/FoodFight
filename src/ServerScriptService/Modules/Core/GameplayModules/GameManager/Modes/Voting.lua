--mode purpose:

--[[
clean up current map(if exists)
clean up any kind of hitboxes, projects, etc
disable combat 
]]

--janin 1/10/26

local Voting = {}

function Voting:InitMode(Core)
	self.FoodCombatController = Core:Get("FoodCombatManager")
	self.GameManager = Core:Get("GameManager")
	self.VoteManager = Core:Get("VoteManager")
	self.TeamManager = Core:Get("TeamManager")
	self.MapManager = Core:Get("MapManager")
	self.MatchStatsManager = Core:Get("MatchStatsManager")

	self.Name = "Voting"
	self.Duration = 5 --typical duration
end

function Voting:StartMode()
	print("starting voting")

	self.VoteManager:EnableVoting()
end

function Voting:OnComplete()
	print("complete voting")
	--clean up leaderboard stats, use team manager to create balanced teams

	self.VoteManager:DisableVoting() --disables votes

	self.TeamManager:CleanupTeams() --clears team table


	

    --get vote winners
	local Map, Mode = self.VoteManager:GetWinners()
	self.MapManager:LoadMap(Map)

	--enable spawning using charactermanager

    --create & balance teams
	self.TeamManager:CreateTeamsFromMode(Mode)
    self.TeamManager:AutoAssignBalancedTeams()

    print(self.TeamManager.Teams)

	task.delay(5, function()
		--enable match stats--

		self.MatchStatsManager:LoadAllPlayers()
		self.GameManager:SetMode(Mode)
	end)
end

return Voting
