local Store = {}

function Store:Init(Core)
    self.MainUI = game.Players.LocalPlayer.PlayerGui.Store
    self.Passes = {}
    self.Auras = {}
    self.Trails = {}

    self.PurchaseEvent = nil --create purchase event

    self.ClientDataController = Core:Get("ClientDataController")
end


function Store:Start()
    local FoodContainer = self.MainUI
end

function Store:OnClose()
    
end

return Store