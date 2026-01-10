--mode description--

--[[

Free for all
given a set amount of time, players are forced to fight each other,
whoever get's the most amount of points wins the round or smtn


]]

local FFA = {}



function FFA:InitMode(Core)

    self.Name = "FFA"
    self.DisplayName = "Free For All"
    self.DescriptionText = "Fight any Player you can find!" -- will be used for countdown
end



function FFA:StartMode()
    print("ffa hooray")
    --use team manager to set all players teams to fighters
    
end

--on end
function FFA:OnComplete()
    
end




return FFA