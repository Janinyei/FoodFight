local RoundTimer = {}

function RoundTimer:Init(Core)
    self.TimerEvent = Core:Get("SharedRemotes"):GetEvent("TimerEvent")
end

function RoundTimer:Start()
    self.TimerEvent:Connect(function(msg : string, TimeRemaining)
        print(msg , TimeRemaining)
    end)
end

return RoundTimer