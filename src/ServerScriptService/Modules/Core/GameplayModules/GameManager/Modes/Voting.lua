

--mode purpose:

--[[
clean up current map(if exists)
clean up any kind of hitboxes, projects, etc
disable combat 
]]

local Voting = {}


function Voting:InitMode(Core)
    self.FoodCombatController = Core:Get("FoodCombatManager")
    self.GameStatusController = Core:Get("GameStatusManager")
    self.GameManager = Core:Get("GameManager")

    self.Name = "Intermission"
    self.Duration = 30 --typical duration


end


function Voting:StartMode()
    --teleport players to lobby screen
    print("starting intermission")
end


function Voting:OnComplete()
    print("complete intermission")
end




return Voting