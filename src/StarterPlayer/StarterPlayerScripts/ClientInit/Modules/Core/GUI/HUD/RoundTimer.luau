local RoundTimer = {}

function RoundTimer:Init(Core)
	local PlayerGui = game.Players.LocalPlayer.PlayerGui

	self.TimerEvent = Core:Get("SharedRemotes"):GetEvent("TimerEvent")
	self.TimerUI = PlayerGui.HUD.Timer
	self.TimeDisplay = self.TimerUI.TimeDisplay
end

function RoundTimer:Start()
	print(self.TimerUI.Name)
	self.TimerEvent:Connect(function(msg: string, TimeRemaining)
		local minutes = tostring(math.floor(TimeRemaining / 60))
		local seconds = tostring(math.floor(TimeRemaining % 60))
 
        if tonumber(minutes) > 0 then 
            self.TimeDisplay.Text = minutes.."m "..seconds.."s"
        elseif tonumber(minutes) <= 0 then
            self.TimeDisplay.Text = seconds.."s"
        end
	
		--self.TimerUI.TimePrefix.Text = msg --doesn't work, it's an image label not a text label
	end)
end

return RoundTimer
