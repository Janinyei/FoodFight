--purpose: keeps track of and handles current match statistics
--janin 12/9/25
local MatchStatsManager = {}
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


--btw these were generated so I may not use all of them
-- Types
export type PlayerMatchData = {
    -- Core Stats
    Kills: number,
    Deaths: number,
    Assists: number,
    Score: number,
    
    -- Combat Stats
    DamageDealt: number,
    DamageTaken: number,
    HealingDone: number,
    ProjectilesFired: number,
    ProjectilesHit: number,
    Accuracy: number,
    CriticalHits: number,
    HeadshotCount: number,
    
    -- Food Specific
    FoodsThrown: {[string]: number},
    FoodHits: {[string]: number},
    UltimatesUsed: number,
    UltimateKills: number,
    
    -- Streak Tracking
    CurrentKillStreak: number,
    BestKillStreak: number,
    CurrentDeathStreak: number,
    IsOnFire: boolean, -- 5+ killstreak
    IsDominating: boolean, -- 10+ killstreak
    
    -- Match Performance
    Points: number,
    ObjectiveScore: number,
    TimeAlive: number,
    LongestLife: number,
    DistanceTraveled: number,
    
    -- Achievements/Medals
    FirstBlood: boolean,
    DoubleKill: number,
    TripleKill: number,
    MultiKill: number,
    Revenge: number,
    Comeback: number,
    Shutdown: number, -- Ended someone's streak
    
    -- Team Stats
    TeamNumber: number,
    FriendlyFire: number,
    ObjectivesCaptured: number,
    ObjectivesDefended: number,
    
    -- Meta Data
    JoinTime: number,
    PlayTime: number,
    AFK: boolean,
    Reported: boolean,
    
    -- Economic (if applicable)
    CoinsEarned: number,
    CoinsSpent: number,
    ItemsPurchased: {[string]: number},
    
    -- Special Events
    Achievements: {[string]: boolean},
    Milestones: {[string]: number}
}



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
            Score = 0,
            
            -- Combat Stats
            DamageDealt = 0,
            DamageTaken = 0,
            HealingDone = 0,
            ProjectilesFired = 0,
            ProjectilesHit = 0,
            Accuracy = 0,
            CriticalHits = 0,
            HeadshotCount = 0,

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