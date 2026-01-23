--purpose: connects with inventory manager to load gui and grants player acccess to modify inventory data
--janin 1/21/25
local InventoryGui = {}

--Services--
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimNation = require(ReplicatedStorage.Modules.Utils.AnimNation)

function InventoryGui:Init(Core)
	self.InventoryGui = PlayerGui.Inventory
    self.ScreenGuiController = Core:Get("ScreenGuiController")
	self.ScreenGuiController.ScreenState.StateChanged:Connect(function(old, new)
		if new == "Inventory" then
			self:OnToggle(true, old)
		elseif old == "Inventory" then
			self:OnToggle(false, new)
		end
	end)
end


function InventoryGui:OnToggle(Open: boolean, otherState: string)
   

	if Open then
		self.InventoryGui.Enabled = true

		--horizontal widening transition--

		--set initial width
		self.InventoryGui.Container.Size = UDim2.fromScale(0, self.InventoryGui.Container.Size.Y.Scale)

		AnimNation.target(
			self.InventoryGui.Container,
			{ Speed = 15, Damper = 0.9 },
			{ Size = UDim2.fromScale(self.InventoryGui.Container.Size.X.Scale, 0.85 )}
		)
	else
		--slide out transition

		AnimNation.target(
			self.InventoryGui.Container,
			{ Speed = 15, Damper = 0.9 },
			{ Position = UDim2.fromScale(0.5, -0.01),
        Size = UDim2.fromScale(0,0)}
		)

		task.delay(1.5, function()
			self.InventoryGui.Enabled = false
            self.InventoryGui.Container.Position = UDim2.fromScale(0.5,0.5)
            self.InventoryGui.Container.Size = UDim2.fromScale(0.75,0.8)

		end)
	end
end

return InventoryGui
