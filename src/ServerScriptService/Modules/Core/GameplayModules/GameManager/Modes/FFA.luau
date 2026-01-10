--mode description--

--[[

Free for all
given a set amount of time, players are forced to fight each other,
whoever get's the most amount of points wins the round or smtn


]]

local FFA = {}



function FFA:Init(Core)
    self.Timer =  nil
    self.DisplayName = "Free For All"
end



--don't shorted to Start or else Core framework will auto run it lol
function FFA:StartGame()
    
end

--on end
function FFA:OnComplete()
    
end






return FFA