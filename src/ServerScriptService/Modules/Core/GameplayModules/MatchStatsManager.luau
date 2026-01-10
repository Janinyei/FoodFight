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

function MatchStatsManager:Init(Core)
	self.PlayerData = {}
	self.LeaderboardEvent = Core:Get("SharedRemotes"):GetEvent("LeaderboardEvent")
	 self.StatChanged = Signal.new()
end

function MatchStatsManager:Start()
	Players.PlayerRemoving:Connect(function(player)
		self:RemovePlayer(player)
	end)
end

function MatchStatsManager:LoadPlayer(player)
	self.PlayerData[player] = {
		-- Core Stats
		Kills = 0,
		Deaths = 0,
		Assists = 0,
		Points = 0,
	}
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
        self.StatChanged:Fire(targetPlr, statName, self.PlayerData[targetPlr][statName])
	end
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
end

function MatchStatsManager:RemoveAllPlayers()
	for _, plr in Players:GetPlayers() do
		self:RemovePlayer(plr)
	end
end

return MatchStatsManager
