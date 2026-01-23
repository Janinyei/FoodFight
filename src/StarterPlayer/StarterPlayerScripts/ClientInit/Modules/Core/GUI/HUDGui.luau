--purpose: controls all gui in the HUD

--note: might wanna move timer code in it's own separate script since I moved the timer gui outside
--the HUD
local HUDGui = {}

--Services--
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimNation = require(ReplicatedStorage.Modules.Utils.AnimNation)

function HUDGui:Init(Core)
	self.SharedRemotes = Core:Get("SharedRemotes")
	self.ScreenGuiController = Core:Get("ScreenGuiController")
	self.TimerEvent = self.SharedRemotes:GetEvent("TimerEvent")
	self.CharacterEvent = self.SharedRemotes:GetEvent("CharacterEvent")

	self.FoodCombatController = Core:Get("FoodCombatController")
	self.HUD = PlayerGui.HUD

	--Timer--
	self.TimerGui = PlayerGui.Timer.TimerFrame
	self.TimeDisplay = self.TimerGui.TimeDisplay

	--Energy
	self.EnergyBarContainer = self.HUD.EnergyBarContainer

	self.ScreenGuiController.ScreenState.StateChanged:Connect(function(old, new)
		if new == "HUD" then
			self:OnToggle(true, old)
		elseif old == "HUD" then
			self:OnToggle(false, new)
		end
	end)
end

function HUDGui:Start()
	self.TimerEvent:Connect(function(Msg, TimeRemaining)
		self:UpdateTimer(Msg, TimeRemaining)
	end)

	self:LoadEnergyBar()
end

--state management--

function HUDGui:OnToggle(Open: boolean, otherState: string)
	if Open then
		self.HUD.Enabled = true
		--play quick transition into load--

		--set up gui

		task.spawn(function()
			local BlackScreen = Instance.new("Frame")
			BlackScreen.Parent = PlayerGui.ScreenEffects
			BlackScreen.Name = "BlackScreen"
			BlackScreen.AnchorPoint = Vector2.new(0.5, 0.5)
			BlackScreen.Position = UDim2.fromScale(0.5, 0.5)
			BlackScreen.Size = UDim2.fromScale(1, 1)
			BlackScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			BlackScreen.BackgroundTransparency = 1
			BlackScreen.Visible = true

			AnimNation.tween(
				BlackScreen,
				TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.In),
				{ BackgroundTransparency = 0 }
			):AndThen(function()
				--request spawn
				self.CharacterEvent:Invoke(8, "Spawn")
				task.wait(0.5)
				AnimNation.tween(
					BlackScreen,
					TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ BackgroundTransparency = 1 }
				):Await()

				game.Debris:AddItem(BlackScreen, 1)
			end)
		end)

	--
	else
		--disable screen gui
		task.delay(0.15, function()
			if self.ScreenGuiController.ScreenState:GetState() ~= "HUD" then
				self.HUD.Enabled = false
			end
		end)
	end
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

	AnimNation.impulse(self.TimerGui.TimeDisplay, { Speed = 10 }, { Position = UDim2.fromScale(0, -1) })
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
