--purpose: handles store transations and purchases and everything

local StoreGui = {}

--Services--
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimNation = require(ReplicatedStorage.Modules.Utils.AnimNation)

function StoreGui:Init(Core)
	self.StoreGui = PlayerGui.Store
    self.ScreenGuiController = Core:Get("ScreenGuiController")
	self.ScreenGuiController.ScreenState.StateChanged:Connect(function(old, new)
		if new == "Store" then
			self:OnToggle(true, old)
		elseif old == "Store" then
			self:OnToggle(false, new)
		end
	end)
end

function StoreGui:Start() end

function StoreGui:OnToggle(Open: boolean, otherState: string)
   

	if Open then
		self.StoreGui.Enabled = true

		--horizontal widening transition--

		--set initial width
		self.StoreGui.Container.Size = UDim2.fromScale(0, self.StoreGui.Container.Size.Y.Scale)

		AnimNation.target(
			self.StoreGui.Container,
			{ Speed = 15, Damper = 0.9 },
			{ Size = UDim2.fromScale(0.75, self.StoreGui.Container.Size.Y.Scale) }
		)
	else
		--slide out transition

		AnimNation.target(
			self.StoreGui.Container,
			{ Speed = 15, Damper = 0.9 },
			{ Position = UDim2.fromScale(0.5, -0.01),
        Size = UDim2.fromScale(0,0)}
		)

		task.delay(1.5, function()
			self.StoreGui.Enabled = false
            self.StoreGui.Container.Position = UDim2.fromScale(0.5,0.5)
            self.StoreGui.Container.Size = UDim2.fromScale(0.75,0.8)

		end)
	end
end

return StoreGui
