-- Imports
local Core = require(game.ReplicatedStorage.Modules.Core)
local Warp = require(game.ReplicatedStorage.Modules.Utils.Warp)

-- Services
local Players = game:GetService("Players")

-- Module
local InventoryManager = {}
local DataManager = nil :: ModuleScript?

-- Events
local InventoryEvent

function InventoryManager:Init()
	--Events--
	InventoryEvent = Warp.Server("InventoryEvent")
	--Modules--
	DataManager = Core:Get("DataManager")
end

function InventoryManager:Start()
	DataManager.DataLoaded:Connect(function(player: string, data: {})
		InventoryEvent:Fire(true, player, data)
	end)
end

--Adds Item to Inventory
function InventoryManager:AddItem(Player: Player, ItemData: { Name: string, Type: string, Amount: number? })
	local PlrData = DataManager:GetData(Player)
	local ExistingItem = self:GetItem(Player, PlrData, ItemData)

	if ExistingItem then
		if ExistingItem.Type ~= "Food" then
			ExistingItem.Amount = (ExistingItem.Amount) + (ItemData.Amount or 1)
        else
            warn("Food is not stackable, do not increase.")
        end
	elseif ExistingItem == nil then --add new item
			local NewItem = ItemData
			PlrData.Inventory[ItemData.Name] = NewItem
	end
		-- replicate to client
        InventoryEvent:Fire(true, Player, PlrData.Inventory)
	end


function InventoryManager:RemoveItem(Player: Player, Item: string, RemoveAll: boolean?)
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
	InventoryEvent:Fire(true, Player, PlrData.Inventory)
end

function InventoryManager:GetItem(Player, PlrData, ItemData: { Name: string, Type: string, Amount: number })
	if PlrData.Inventory and PlrData.Inventory[ItemData.Type][ItemData.Name] then
		return PlrData.Inventory[ItemData.Type][ItemData.Name]
	end

	return nil
end

function InventoryManager:HasItem(Player: Player, Item: string)
	local PlrData = DataManager:GetData(Player)
	if not PlrData or not PlrData.Inventory then
		warn(`[InventoryManager] invalid inventory: {Player.Name}`)
		return false
	end
	return PlrData.Inventory[Item] ~= nil
end

return InventoryManager
