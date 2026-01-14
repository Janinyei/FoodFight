--mode description--

--[[

starts a countdown with OnTick

]]

local Countdown =  {}



function Countdown:InitMode(Core)
    self.Name = "Countdown"
    self.GameManager = Core:Get("GameManager")
    self.Duration = 5
end



function Countdown:StartMode()

end

function Countdown:OnTick()
    --fire special event to make gui countdown play
    print("count down tick")
end

--on end
function Countdown:OnComplete()
    self.GameManager:SetMode("FFA")

    
end




return Countdown