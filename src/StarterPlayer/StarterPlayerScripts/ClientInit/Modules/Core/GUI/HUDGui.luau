--purpose: controls all gui in the HUD

local HUDGui = {}

--Services--
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui

function HUDGui:Init(Core)
	self.SharedRemotes = Core:Get("SharedRemotes")
	self.TimerEvent = self.SharedRemotes:GetEvent("TimerEvent")
	self.HUD = PlayerGui.HUD
	--gui variables--

	--Timer--
	self.TimerGui = self.HUD.Timer
	self.TimeDisplay = self.TimerGui.TimeDisplay
end

function HUDGui:Start()
	self.TimerEvent:Connect(function(Msg, TimeRemaining)
   
        self:UpdateTimer(Msg, TimeRemaining)
    end)
end

function HUDGui:UpdateTimer(Msg, TimeRemaining: number)
	
    self.TimerGui.Status.Text = Msg

	local minutes = tostring(math.floor(TimeRemaining / 60))
	local seconds = tostring(math.floor(TimeRemaining % 60))

	if tonumber(minutes) > 0 then
		self.TimeDisplay.Text = minutes .. "m " .. seconds .. "s"
	elseif tonumber(minutes) <= 0 then
		self.TimeDisplay.Text = seconds .. "s"
	end


end

return HUDGui
