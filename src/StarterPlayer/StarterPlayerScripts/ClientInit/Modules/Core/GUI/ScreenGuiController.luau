--purpose: Loads entire game GUI, holds general utilities and controls UI navigation. Very important script
--note: if something's not working, make sure that the module's priority attribute is working
--janin 10/28/25

--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

--Variables--
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

--util--
local StateMachine = require(ReplicatedStorage.Modules.Utils.StateMachine)
local ScreenGuiController = {}

--Puts all ScreenGui in PlayerGui
function ScreenGuiController:Init()
	self.Screens = {}
	self.CurrentScreen = nil
	self.ScreenState = StateMachine.new()

	ScreenGuiController:LoadGUI()
end

function ScreenGuiController:Start(Core)
	--don't put self:LoadGUI in here ts will not work lol
	--self:SetScreen("Menu")

	--start off with menu

	self.ScreenState:SetState("Menu")

    task.spawn(function()
            while true do

                task.wait(3)
                
             --   self.ScreenState:SetState("Menu")
    
                task.wait(2)
    
             --   self.ScreenState:SetState("HUD")
            end
        end)
	
end

function ScreenGuiController:CloseScreen(ScreenName: string)
	local Screen = self.Screens[ScreenName]
	if Screen then
		Screen.Enabled = false
		self.CurrentScreen = nil
	end
end

--Purpose: to avoid endless WaitForChilds, trust me, it works
function ScreenGuiController:LoadGUI()
	--unload UI cache folder contents
	for _, UI in ReplicatedStorage.UICache:GetChildren() do
		if UI:IsA("ScreenGui") then
			UI.Parent = PlayerGui
		end
	end
	ReplicatedStorage.UICache:Destroy() -- removes empty folder after unloading contents
end

return ScreenGuiController
