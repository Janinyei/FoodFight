
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Imports--
local Warp = require(game.ReplicatedStorage.Modules.Utils.Warp)


-- Module
local InventoryController = {}

--Events--
local InventoryEvent

-- Types
type inventory = { [string]: { Name: string, Amount: number, Upgrades: { [string]: any } } }

function updateUI(Inventory: inventory)
    -- TODO: , tzu
end


function InventoryController:Init()
    self.Inventory = {}
    InventoryEvent = Warp.Client("InventoryEvent")

     InventoryEvent:Connect(function(inventory: {})
        print(inventory)
    end)
end

function  InventoryController:Start()
   
end

return InventoryController