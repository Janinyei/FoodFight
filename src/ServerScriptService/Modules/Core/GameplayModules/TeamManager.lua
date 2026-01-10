--purpose: manages team assignment and rebalancing
-- note: does not use traditional roblox teams and instead uses tables
--janin 1/10/26


local TeamManager = {}
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
        Config = TeamConfig[TeamName]
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

--auto assigns players to balanced teams
function TeamManager:AutoAssignBalancedTeams()
    --simple round robin assignment for now
    local teamNames = {}
    for tName, team in pairs(self.Teams) do
        team.Players = {} --clear current players
        table.insert(teamNames, tName)
    end

    local players = Players:GetPlayers()
    for i, plr in pairs(players) do
        local teamIndex = ((i - 1) % #teamNames) + 1
        self:AssignPlayerToTeam(plr, teamNames[teamIndex])
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


return TeamManager
