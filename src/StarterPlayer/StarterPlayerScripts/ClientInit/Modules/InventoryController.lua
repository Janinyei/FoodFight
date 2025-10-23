-- Imports
local NetRay = require(game.ReplicatedStorage.Modules.NetRay)
local Core = require(game.ReplicatedStorage.Modules.Core)

-- Services

-- Module
local InventoryController = {}


-- Types
type inventory = { [string]: { Name: string, Amount: number, Upgrades: { [string]: any } } }

function updateUI(Inventory: inventory)
    -- TODO: , tzu
end

function InventoryController:Init()
    self.Inventory = {}
    local InventoryAddedEvent = NetRay:GetEvent("InventoryAdded")
    InventoryAddedEvent:OnEvent(function(Inventory: inventory)
        self.Inventory = Inventory
        updateUI(Inventory)

        print(Inventory)
    end)
end

return InventoryController