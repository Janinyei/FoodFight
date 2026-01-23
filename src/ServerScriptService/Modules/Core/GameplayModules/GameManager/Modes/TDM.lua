--mode description--

--[[

Free for all
given a set amount of time, players are forced to fight each other,
whoever get's the most amount of points wins the round or smtn


]]

local GameConstants = require(game.ReplicatedStorage.Modules.Info.GameConstants)
local FFA = {}

function FFA:InitMode(Core)
    self.Name = "TDM"
    self.DisplayName = "Team Death Match"
    self.Duration = GameConstants.ROUND_DURATION
end



function FFA:StartMode()
    print("ffa hooray")
    --use team manager to set all players teams to fighters
    
end

--on end
function FFA:OnComplete()
    
end




return FFA