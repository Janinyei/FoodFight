

--mode purpose:

--[[
clean up current map(if exists)
clean up any kind of hitboxes, projects, etc
disable combat 
teleport players
]]

local Intermission = {}


function Intermission:InitMode(Core)
    self.FoodCombatController = Core:Get("FoodCombatManager")
    self.GameStatusController = Core:Get("GameStatusManager")
    self.GameManager = Core:Get("GameManager")
    self.MapManager = Core:Get("MapManager")

    self.Name = "Intermission"
    self.Duration = 30 --typical duration


end


function Intermission:StartMode()
    --teleport players to lobby screen


    --clean up map--
    self.MapManager:CleanupCurrentMap()

    --disable combat--


    
end


function Intermission:OnComplete()
    print("complete intermission")
end


function Intermission:OnTick(TimeRemaining : number)
    print("tick tock ".. TimeRemaining)

    if TimeRemaining <= 15 then
        self:_tpPlayersToLobby()
    end

end



function Intermission:_tpPlayersToLobby()
    
end



return Intermission