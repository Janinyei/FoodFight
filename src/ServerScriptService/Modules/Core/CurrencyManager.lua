-- Services

-- Modules
local CurrencyManager = {}
local DataManager = nil :: ModuleScript?


function CurrencyManager:Init(Core)
	--Events--
	self.CurrencyEvent = Core:Get("SharedRemotes"):GetEvent("CurrencyEvent")
	--Modules--
	DataManager = Core:Get("DataManager")
end

function CurrencyManager:Start()
	DataManager.DataLoaded:Connect(function(Player: Player, Data)
        print(Data.Currency)
		self.CurrencyEvent:Fire(true, Player, Data.Currency)
	end)
end

function CurrencyManager:AddCurrency(Player: Player, Type: string, Amount: number)
	local PlrData = DataManager:GetData(Player)
	PlrData.Currency[Type] = PlrData.Currency[Type] + Amount
	-- Replicate to client
	self.CurrencyEvent:Fire(true, Player, PlrData.Currency)
	return PlrData.Currency[Type]
end

function CurrencyManager:RemoveCurrency(Player: Player, Type: string, Amount: number)
	local PlrData = DataManager:GetData(Player)
	-- Check if player has enough of 'Type' currency
	if PlrData.Currency[Type] < Amount then
		warn(`[CurrencyManager] {Player.Name} doesnt have enough {Type}`)
		return false
	end
	PlrData.Currency[Type] = PlrData.Currency[Type] - Amount
	-- Replicate to client
	self.CurrencyEvent:Fire(true, Player, PlrData.Currency)
	return true
end

function CurrencyManager:CanAfford(Player: Player, Type: string, Amount: number)
	local PlrData = DataManager:GetData(Player)
	
	if not PlrData or not PlrData.Currency then
		return false
	end
	
	return PlrData.Currency[Type] >= Amount
end

return CurrencyManager