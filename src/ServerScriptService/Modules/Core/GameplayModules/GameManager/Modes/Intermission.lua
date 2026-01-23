

--mode purpose:

--[[
clean up current map(if exists)
clean up any kind of hitboxes, projects, etc
disable combat 
teleport players
]]

--janin 1/10/26

local GameConstants = require(game.ReplicatedStorage.Modules.Info.GameConstants)
local Intermission = {}


function Intermission:InitMode(Core)
    self.FoodCombatController = Core:Get("FoodCombatManager")
    self.MatchStatsManager = Core:Get("MatchStatsManager")
    self.GameManager = Core:Get("GameManager")
    self.MapManager = Core:Get("MapManager")
    self.AudioManager = Core:Get("AudioManager")

    self.Name = "Intermission"
    self.Duration = GameConstants.INTERMISSION_DURATION
end


function Intermission:StartMode()
    --teleport players to lobby screen

    
    --clean up map--
    self.MapManager:CleanupCurrentMap()
 
    --disable combat--


    --cleanup match stats
    self.MatchStatsManager:RemoveAllPlayers()

    --play some intermission music
    self.AudioManager:PlayRandomSong("Intermission")
    
    
end


function Intermission:OnComplete()
    print("complete intermission")

    task.wait(3) --delay
    self.GameManager:SetMode("Voting")
end


function Intermission:OnTick(TimeRemaining : number)
    --just to show this here ig idk
end



function Intermission:_tpPlayersToLobby()
    print("does nothing lol")
end



return Intermission