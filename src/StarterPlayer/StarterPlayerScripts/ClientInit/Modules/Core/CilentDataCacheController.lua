-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports
local Warp = require(ReplicatedStorage.Modules.Utils.Warp)
local Signal = require(ReplicatedStorage.Modules.Utils.Signal)

-- Module
local CilentDataCacheController = {}

-- Events
local CurrencyEvent
local InventoryEvent
-- Types
type currencyType = { Coins: number, Gems: number }
type inventoryType = { [string]: { Name: string, Type: string, Amount: number } }

-- Local Functions
local function updateCurrencyUI(Currency: currencyType)
	print(Currency)
end

local function updateInventoryUI(Inventory: inventoryType)
    print(Inventory)
end

-- Signals
function CilentDataCacheController:Init()
	self.Currency = {
		Coins = 0,
		Gems = 0
	}
	self.Inventory = {}
    -- Signals
	self.CurrencyChanged = Signal.new()
	self.InventoryChanged = Signal.new()

	print(self)
end

function CilentDataCacheController:Start()
	CurrencyEvent = Warp.Client("CurrencyEvent")
	InventoryEvent = Warp.Client("InventoryEvent")

	print("START")

	CurrencyEvent:Connect(function(Currency: currencyType)
		print(Currency)
		self.Currency = Currency
		updateCurrencyUI(Currency)
		self.CurrencyChanged:Fire(Currency)
	end)
	
	InventoryEvent:Connect(function(Inventory: inventoryType)
		print(CurrencyEvent)
		self.Inventory = Inventory
		updateInventoryUI(Inventory)
		self.InventoryChanged:Fire(Inventory)
	end)
end

-- Wrappers
function CilentDataCacheController:GetCurrency()
	return self.Currency
end

function CilentDataCacheController:GetInventory()
	return self.Inventory
end

function CilentDataCacheController:GetItem(ItemType: string, ItemName: string)
	if self.Inventory[ItemType] then
		return self.Inventory[ItemType][ItemName]
	end
	return nil
end

function CilentDataCacheController:GetItemAmount(ItemType: string, ItemName: string)
	local item = self:GetItem(ItemType, ItemName)
	return item and item.Amount or 0
end

return CilentDataCacheController