--purpose: manages team assignment and rebalancing
-- note: does not use traditional roblox teams and instead uses tables
--janin 1/10/26


local TeamManager = {}

--moduels--
local ModeConfig = require(game.ReplicatedStorage.Modules.Info.ModeConfig)
local TeamConfig = require(game.ReplicatedStorage.Modules.Info.TeamConfig)
local Signal = require(game.ReplicatedStorage.Modules.Utils.Signal)
-- Services
local Players = game:GetService("Players")


function TeamManager:Init(Core)
    self.Teams = {}
    self.MatchStatsManager =  Core:Get("MatchStatsManager")
    
    self.TeamPlayerUpdated  = Signal.new()
    
    
end

function  TeamManager:Start()
    Players.PlayerAdded:Connect(function(plr)
        --assign to team on join
        self:AssignNewPlayer(plr)
    end)
end

--creates team, necessary before balancing
function TeamManager:CreateTeam(TeamName : string)
    if not TeamConfig[TeamName] then
         warn('team config not found for ' .. TeamName) 
        return
    end

    self.Teams[TeamName] = {
        Players = {},
        Config = TeamConfig[TeamName],
        Points = 0,
    }
end

--removes a team
function TeamManager:RemoveTeam(TeamName : string)

    if self.Teams[TeamName] == nil then
        warn('team ' .. TeamName .. ' does not exist')
        return
    end

    self.Teams[TeamName] = nil
end

--removes all teams
function TeamManager:CleanupTeams()
    self.Teams = {}
end

function TeamManager:GetTeam(TargetPlayer:Player)
    for TeamName, Team in pairs(self.Teams) do
        if Team.Players[TargetPlayer] then
            return TeamName
        end
    end

    return nil
end

--sets a player's team
function TeamManager:AssignPlayerToTeam(plr : Player, TeamName : string)
    if self.Teams[TeamName] == nil then
        warn('team ' .. TeamName .. ' does not exist')
        return
    end

    --remove from other teams
    for tName, team in pairs(self.Teams) do
        for i, teamPlr in pairs(team.Players) do
            if teamPlr == plr then
                table.remove(team.Players, i)
            end
        end
    end

    table.insert(self.Teams[TeamName].Players, plr)
end

-- auto assigns players to balanced teams
function TeamManager:AutoAssignBalancedTeams()
    -- FIX: Use next() to check if a dictionary is empty
    if next(self.Teams) == nil then
        warn("no teams to assign")
        return
    end

    -- simple round robin assignment for now
    local teamNames = {}
    for tName, team in pairs(self.Teams) do
        team.Players = {} -- clear current players
        table.insert(teamNames, tName)
    end

    local players = Players:GetPlayers()
    for i, plr in pairs(players) do
        -- Double check that teamNames actually populated
        if #teamNames > 0 then
            local teamIndex = ((i - 1) % #teamNames) + 1
            self:AssignPlayerToTeam(plr, teamNames[teamIndex])
        end
    end
end
--assigns team in a balanced fashion to new players
function TeamManager:AssignNewPlayer(plr : Player)

    if #self.Teams < 1 then return end

    --assign to smallest team
    local smallestTeamName = nil
    local smallestSize = math.huge

    for tName, team in pairs(self.Teams) do
        if #team.Players < smallestSize then
            smallestSize = #team.Players
            smallestTeamName = tName
        end
    end

    if smallestTeamName then
        self:AssignPlayerToTeam(plr, smallestTeamName)
    else
        warn('no teams available to assign player to')
    end 
end


--creates team based on mode config

function TeamManager:CreateTeamsFromMode(modeName : string)
    local teamTable = ModeConfig[modeName].Teams

    for _, teamName in teamTable do
        self:CreateTeam(teamName)
    end
end


return TeamManager
