--purpose: keeps track of and handles current match statistics on the server
--note: connects with leaderboard gui to update stats for specific players to display.
--note : this script makes changes to the leaderboard gui, but doesn't make the leaderboard manager obsolete.
--janin 12/9/25
local MatchStatsManager = {}
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(game.ReplicatedStorage.Modules.Utils.Signal)

--btw these were generated so I may not use all of them

local defaultMatchStats = {
	Kills = 0,
		Assists = 0,
		Points = 0,
}

function MatchStatsManager:Init(Core)
	self.PlayerData = {}
	self.LeaderboardEvent = Core:Get("SharedRemotes"):GetEvent("LeaderboardEvent")
	self.GameManager = Core:Get("GameManager")
<<<<<<< HEAD
	self.StatsChanged = Signal.new()
	self.TeamScores = {}
	self.TeamStatsChanged = Signal.new()
=======
	 self.StatsChanged = Signal.new()
	 self.TeamScores = {}
	 self.TeamStatsChanged = Signal.new()
>>>>>>> ce0094f2300b056a1c675f33ea0784e54d2d28e7
end

function MatchStatsManager:Start()

	Players.PlayerAdded:Connect(function(player)
		if self.GameManager.InGame then  
			self:LoadPlayer(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:RemovePlayer(player)
	end)


end

function MatchStatsManager:LoadPlayer(player)
	self.PlayerData[player] = defaultMatchStats


	--fire stats changed for initial update
	self.StatsChanged:Fire(player, self.PlayerData[player])
end

function MatchStatsManager:Increment(targetPlr: Player, statName: string, amount: number?)
	if not targetPlr then
		warn("player not provided")
		return
	end
	if not statName then
		warn("stat name not provided")
		return
	end

	if self.PlayerData[targetPlr] and self.PlayerData[targetPlr][statName] then
		local Amt = amount or 1
		self.PlayerData[targetPlr][statName] += Amt
        self.StatsChanged:Fire(targetPlr, self.PlayerData[targetPlr])
	end
end

function MatchStatsManager:IncrementTeam(TeamName: string, statName: string, amount: number?)
	if not self.TeamScores[TeamName] then
		self.TeamScores[TeamName] = {}
	end
	
	if not self.TeamScores[TeamName][statName] then
		self.TeamScores[TeamName][statName] = 0
	end
	
	local Amt = amount or 1
	self.TeamScores[TeamName][statName] += Amt
	self.TeamStatsChanged:Fire(TeamName, self.TeamScores[TeamName])
end

function MatchStatsManager:ResetTeamScores()
	self.TeamScores = {}
	self.TeamStatsChanged:Fire("All", {})
end

function MatchStatsManager:LoadAllPlayers()
	for _, plr in Players:GetPlayers() do
		self:LoadPlayer(plr)
	end
end

function MatchStatsManager:RemovePlayer(player)
	if self.PlayerData[player] then
		self.PlayerData[player] = nil
	end

	--fires statschanged to reset leaderboard

	self.StatsChanged:Fire( player , defaultMatchStats)
end

function MatchStatsManager:RemoveAllPlayers()
	for _, plr in Players:GetPlayers() do
		self:RemovePlayer(plr)
	end
end

return MatchStatsManager
