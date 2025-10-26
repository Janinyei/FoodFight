
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Imports--
local Warp = require(game.ReplicatedStorage.Modules.Utils.Warp)


-- Module
local InventoryController = {}

--Events--
local InventoryEvent

-- Types
type inventory = { [string]: { Name: string, Type: string, Amount: number } }


-- Local Functions
local function updateUI(Inventory: inventory)
    -- TODO: , tzu
end


-- Main Functions

function InventoryController:Init()
    self.Inventory = {}

end

function  InventoryController:Start()
    InventoryEvent = Warp.Client("InventoryEvent")
    InventoryEvent:Connect(function(Inventory:inventory)
        updateUI(Inventory)
    end)
end

function InventoryController:EquipItem()
    
end

return InventoryController