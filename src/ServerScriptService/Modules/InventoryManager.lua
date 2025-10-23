-- Imports
local Core = require(game.ReplicatedStorage.Modules.Core)
local NetRay = require(game.ReplicatedStorage.Modules.NetRay)

-- Services
local Players = game:GetService("Players")

-- Module
local InventoryManager = {}
local DataManager=nil :: ModuleScript?

-- Events
local InventoryAddedEvent
function InventoryManager:AddItem(Player:Player, 
    Data:{Item:string, Amount: number?, Upgrades: { [string]: any }}
)
    local PlrData = DataManager:GetData(Player)

    local existing = PlrData.Inventory[Data.Item]
    if existing then
        -- add to amount if existing amount is not nil
        -- merge the upgrades if existing upgrades is not nil
        existing.Amount = (existing.Amount or 1) + (Data.Amount or 1)
        for k, v in pairs(Data.Upgrades or {}) do
            existing.Upgrades[k] = existing.Upgrades[k] or v
        end
    else
        PlrData.Inventory[Data.Item] = {
            Name = Data.Item,
            Amount = Data.Amount or 1,
            Upgrades = Data.Upgrades or {}
        }
    end
    -- replicate to client
    InventoryAddedEvent:FireClient(Player, {
        Inventory = PlrData.Inventory
    })
end

function InventoryManager:RemoveItem(Player:Player, Item:string, RemoveAll: boolean?)
    local PlrData = DataManager:GetData(Player)
    if not PlrData or not PlrData.Inventory then
        warn(`[InventoryManager] invalid inventory: {Player.Name}`)
        return
    end

    local existing = PlrData.Inventory[Item]
    if not existing then
        warn(`[InventoryManager] {Player.Name} does not have {Item}`)
        return
    end

    -- remove the item if amount is 0 or less, or if RemoveAll
    -- else decrease the number amount
    if RemoveAll or (existing.Amount or 1) <= 1 then
        PlrData.Inventory[Item] = nil
    else
        existing.Amount = (existing.Amount or 1) - 1
    end
    -- replicate to client
    InventoryAddedEvent:FireClient(Player, {
        Inventory = PlrData.Inventory
    })
end

function InventoryManager:HasItem(Player:Player, Item:string)
    local PlrData = DataManager:GetData(Player)
    if not PlrData or not PlrData.Inventory then
        warn(`[InventoryManager] invalid inventory: {Player.Name}`)
        return false
    end
    return PlrData.Inventory[Item] ~= nil
end

function InventoryManager:Init()
    DataManager = Core:Get("DataManager")
    InventoryAddedEvent = NetRay:RegisterEvent("InventoryAdded",{
       --[[typeDefinition = {
            Inventory = "Dict<string, any>" -- dictionary with string keys, any value
        }]] 
    })
    -- replicate the inventory for each player when they join
  
    DataManager.DataLoaded:Connect(function(player : string, data :  {})
         InventoryAddedEvent:FireClient(player, {
            Inventory = data.Inventory
        })
    end)
end

return InventoryManager
