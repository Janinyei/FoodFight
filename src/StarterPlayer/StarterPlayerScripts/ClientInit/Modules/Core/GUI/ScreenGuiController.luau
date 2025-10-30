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
    self.ScreenNames = {"Shop", "Settings", "Foods"}
    self:LoadGUI() --Puts all ScreenGui in PlayerGui
end

function ScreenGuiController:Start()
--don't put self:LoadGUI in here ts will not work lol
end

function ScreenGuiController:SetScreen(Screen : ScreenGui) --name of Screen Gui
    
end

function ScreenGuiController:CloseScreen(Screen : ScreenGui)
    
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