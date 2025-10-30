local Food = {}


function Food:Init()
    self.MainUI = game.Players.LocalPlayer.PlayerGui.Food
    self.FoodIcons = {
        ["Burger"] = "",
        [""] = nil ,
    }

end

return Food