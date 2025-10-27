-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports
local Warp = require(ReplicatedStorage.Modules.Utils.Warp)
local Signal = require(ReplicatedStorage.Modules.Utils.Signal)

-- Module
local ClientDataCacheController = {}

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
function ClientDataCacheController:Init(Core)
	--create cache
	self.Currency = {
		Coins = 0,
		Gems = 0,
	}
	self.Inventory = {}
	-- Signals
	self.CurrencyChanged = Signal.new()
	self.InventoryChanged = Signal.new()

	local SharedRemotes = Core:Get("SharedRemotes")

	--Events--
	self.DataEvent = SharedRemotes:GetEvent("DataEvent")
	self.CurrencyEvent = SharedRemotes:GetEvent("CurrencyEvent")
	self.InventoryEvent = SharedRemotes:GetEvent("InventoryEvent")

	--load initial values
	local InitData = self.DataEvent:Invoke(30)
	print(InitData) --test(delete later)

	self.Currency = InitData.Currency
	self.Inventory = InitData.Gems
end

function ClientDataCacheController:Start()

	--instantiate connections(idk if I should put this in here or Init() but either should work fine)
	self.CurrencyEvent:Connect(function(Currency: currencyType)
		self.Currency = Currency
		updateCurrencyUI(Currency)
		self.CurrencyChanged:Fire(Currency)
	end)

	self.InventoryEvent:Connect(function(Inventory: inventoryType)
		self.Inventory = Inventory
		updateInventoryUI(Inventory)
		self.InventoryChanged:Fire(Inventory)
	end)
end

-- Wrappers
function ClientDataCacheController:GetCurrency()
	return self.Currency
end

function ClientDataCacheController:GetInventory()
	return self.Inventory
end

function ClientDataCacheController:GetItem(ItemType: string, ItemName: string)
	if self.Inventory[ItemType] then
		return self.Inventory[ItemType][ItemName]
	end
	return nil
end

function ClientDataCacheController:GetItemAmount(ItemType: string, ItemName: string)
	local item = self:GetItem(ItemType, ItemName)
	return item and item.Amount or 0
end

return ClientDataCacheController
