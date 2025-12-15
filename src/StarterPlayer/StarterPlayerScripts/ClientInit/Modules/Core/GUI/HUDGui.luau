--purpose: controls all gui in the HUD

--note: might wanna move timer code in it's own separate script since I moved the timer gui outside 
--the HUD
local HUDGui = {}

--Services--
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui

function HUDGui:Init(Core)
	self.SharedRemotes = Core:Get("SharedRemotes")
	self.TimerEvent = self.SharedRemotes:GetEvent("TimerEvent")
	self.FoodCombatController = Core:Get("FoodCombatController")
	self.HUD = PlayerGui.HUD
	
	--Timer--
	self.TimerGui = PlayerGui.Timer.TimerFrame
	self.TimeDisplay = self.TimerGui.TimeDisplay

	--Energy
	self.EnergyBarContainer = self.HUD.EnergyBarContainer
end

function HUDGui:Start()
	self.TimerEvent:Connect(function(Msg, TimeRemaining)
		self:UpdateTimer(Msg, TimeRemaining)
	end)
	
	self:LoadEnergyBar()
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

--Load functions--
function HUDGui:LoadEnergyBar()

	self.EnergyChanged = self.FoodCombatController.EnergyChanged


	local EnergyBar = self.EnergyBarContainer.Bar
	local EnergyText = EnergyBar.EnergyCount


	self.EnergyChanged:Connect(function(data)

		local Energy = data.Energy
		local MaxEnergy = data.MaxEnergy
		TweenService:Create(
			EnergyBar,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.fromScale(Energy / MaxEnergy, EnergyBar.Size.Y.Scale) }
		):Play()

		EnergyText.Text = Energy .. " | " .. MaxEnergy
	end)
end

return HUDGui
