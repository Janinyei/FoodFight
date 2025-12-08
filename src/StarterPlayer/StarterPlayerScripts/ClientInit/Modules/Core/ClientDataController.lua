--Purpose: Create a controlled and replicated clone of player's data for centralized access

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


-- Signals
function ClientDataCacheController:Init(Core)
	--create cache
	self.DataCache = {}
	-- Signals
	self.CurrencyChanged = Signal.new()
	self.InventoryChanged = Signal.new()
	self.ProgressionChanged = Signal.new()

	local SharedRemotes = Core:Get("SharedRemotes")

	--Events--
	self.DataEvent = SharedRemotes:GetEvent("DataEvent")

	self.CurrencyEvent = SharedRemotes:GetEvent("CurrencyEvent")
	self.InventoryEvent = SharedRemotes:GetEvent("InventoryEvent")
	self.ProgressionEvent = SharedRemotes:GetEvent("ProgressionEvent")

	--load initial tables
	local InitData = self.DataEvent:Invoke(30)
	
	self.DataCache.Currency = InitData.Currency
	self.DataCache.Inventory = InitData.Inventory
	self.DataCache.Progression = InitData.Progression

		

	--instantiate connections
	self.CurrencyEvent:Connect(function(CurrencyData: currencyType)
		self.DataCache.Currency = CurrencyData
		self.CurrencyChanged:Fire(CurrencyData)
	end)

	self.InventoryEvent:Connect(function(Inventory: inventoryType)
		print("inventory updated")
		self.DataCache.Inventory = Inventory
		self.InventoryChanged:Fire(Inventory)
	end)


	self.ProgressionEvent:Connect(function(ProgressionData) --since max exp isn't saved, we keep it separate
		self.Progression = ProgressionData
		self.ProgressionChanged:Fire(ProgressionData)
	end)
end


function ClientDataCacheController:Start()

	--Fire off events once to load GUI
	self.CurrencyChanged:Fire(self.DataCache.Currency)
	self.ProgressionChanged:Fire(self.DataCache.Progression)
	

end

-- Wrappers

--Currency--
function ClientDataCacheController:GetCurrency()
	return self.DataCache.Currency
end

--Inventory--
function ClientDataCacheController:GetInventory()
	return self.DataCache.Inventory
end

function ClientDataCacheController:GetItem(ItemType: string, ItemName: string)
	if self.DataCache.Inventory[ItemType] then
		return self.DataCache.Inventory[ItemType][ItemName]
	end
	return nil
end

function ClientDataCacheController:GetItemAmount(ItemType: string, ItemName: string)
	local item = self:GetItem(ItemType, ItemName)
	return item and item.Amount or 0
end

return ClientDataCacheController
