--purpose: keeps track of and handles current match statistics
--janin 12/9/25
local MatchStatsManager = {}
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


--btw these were generated so I may not use all of them



function MatchStatsManager:Init(Core)
    self.PlayerData = {}
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

function  MatchStatsManager:LoadAllPlayers()
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