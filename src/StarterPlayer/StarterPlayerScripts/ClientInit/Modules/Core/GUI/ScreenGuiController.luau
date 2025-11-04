--purpose: Loads entire game GUI, holds general utilities and controls UI navigation. Very important script
--note: if something's not working, make sure that the module's priority attribute is working
--janin 10/28/25


--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--Variables--
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local ScreenGuiController = {}


function ScreenGuiController:Init()
    self.Screens = {}   
    self.ScreenNames = {"HUD", "KillCam", "Menu", "Store"} --list of screens that cannot be enabled at the same time
    self.CurrentScreen = nil
    self:LoadGUI() --Puts all ScreenGui in PlayerGui
end

function ScreenGuiController:Start()
--don't put self:LoadGUI in here ts will not work lol
self:SetScreen("Menu")
end

function ScreenGuiController:SetScreen(ScreenName : string) --name of Screen Gui
    --closes current screen if there is one
    if self.CurrentScreen then 
        self:CloseScreen(self.CurrentScreen.Name)
    end

    --opens new screen
    local Screen = self.Screens[ScreenName]
    if Screen then
        Screen.Enabled = true
        self.CurrentScreen = Screen
    else
        warn("Unknown screen name: " .. ScreenName)
    end
end

function ScreenGuiController:CloseScreen(ScreenName : string)
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
            if table.find(self.ScreenNames, UI.Name) ~= nil then
            self.Screens[UI.Name] = UI 
            end
        end
    end
    ReplicatedStorage.UICache:Destroy()-- removes empty folder after unloading contents
end


--HUD--
function ScreenGuiController:HideHUD()
    
end

function ScreenGuiController:ShowHUD()
    
end



return ScreenGuiController