-- Imports
local Core = require(game.ReplicatedStorage.Modules.Core)
local Warp = require(game.ReplicatedStorage.Modules.Utils.Warp)
-- Services

-- Module
local InventoryManager = {}
local DataManager = nil :: ModuleScript?


function InventoryManager:Init(Core)
	--Events--
	self.InventoryEvent = Core:Get("SharedRemotes"):GetEvent("InventoryEvent")
	--Modules--
	DataManager = Core:Get("DataManager")

end

function InventoryManager:Start()
	DataManager.DataLoaded:Connect(function(Player: Player, Data)
		self.InventoryEvent:Fire(true, Player, Data.Inventory)
	end)


	self.InventoryEvent:Connect(function(player, action, ItemType, ItemName)
		if action ==  "EquipItem" then
			local PlrData = DataManager:GetData(player)
			PlrData.Inventory.Equipped[ItemType] = ItemName
			-- replicate to client
			self.InventoryEvent:Fire(true, player, PlrData.Inventory)
		end
	end)
end

--Adds Item to Inventory
function InventoryManager:AddItem(Player: Player, ItemData: { Name: string, Type: string, Amount: number? })
	local PlrData = DataManager:GetData(Player)
	local ExistingItem = self:GetItem(Player, PlrData, ItemData)

	if ExistingItem then
		if ExistingItem.Type ~= "Food" and ExistingItem.Amount then
			ExistingItem.Amount = (ExistingItem.Amount) + (ItemData.Amount or 1)
        else
            warn("Food is not stackable, do not increase.")
        end
	elseif ExistingItem == nil then --add new item
		local NewItem = ItemData
		PlrData.Inventory[ItemData.Type][ItemData.Name] = NewItem
	end
	-- replicate to client
    self.InventoryEvent:Fire(true, Player, PlrData.Inventory)
end

function InventoryManager:RemoveItem(Player: Player, ItemData:{Name: string, Type:string}, RemoveAll: boolean?)
	local PlrData = DataManager:GetData(Player)
	local ExistingItem = self:GetItem(Player,PlrData,ItemData)

	if not ExistingItem then
		warn(`[InventoryManager] {Player.Name} does not have {ItemData.Name}`)
		return
	end
	-- remove the item if amount is 0 or less, or if RemoveAll
	-- else decrease the number amount
	if RemoveAll or (ExistingItem.Amount and ExistingItem.Amount <= 1) then
		PlrData.Inventory[ItemData.Type][ItemData.Name] = nil
	else
		ExistingItem.Amount = ExistingItem.Amount and ExistingItem.Amount - 1
	end
	-- replicate to client
	self.InventoryEvent:Fire(true, Player, PlrData.Inventory)
end

function InventoryManager:GetItem(Player:Player, PlrData, ItemData: { Name: string, Type: string})
	if PlrData.Inventory and PlrData.Inventory[ItemData.Type][ItemData.Name] then
		return PlrData.Inventory[ItemData.Type][ItemData.Name]
	end

	return nil
end

function InventoryManager:HasItem(Player: Player, Item: string)
	local PlrData = DataManager:GetData(Player)
	return PlrData.Inventory[Item] ~= nil
end

return InventoryManager