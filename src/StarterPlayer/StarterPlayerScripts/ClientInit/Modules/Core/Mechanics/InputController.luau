--Purpose: Controls input for players 
--janin: 12/10/25

local InputController = {}
--Services--
local CAS = game:GetService("ContextActionService")


function InputController:Init()
    self.Binds = {
        ["action name"] = {
            ["Keyboard"] = "idk",
            ["Gamepad"] = "idk either"
        } 
    }

    self.OnBindPress = nil --Signal
end



return InputController