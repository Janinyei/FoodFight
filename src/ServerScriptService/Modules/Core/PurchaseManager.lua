--Purpose: handles strictly game purchases. NOT MICRO-TRANSACTIONS, I REPEAT, NOT MICRO-TRANSACTIONS
-- janin 10/24/25

--Imports--
local PurchaseManager = {}


--Services-
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--Modules--
local Modules = ReplicatedStorage.Modules
local Core = require(Modules.Core)
local DataManager


function PurchaseManager:Init()
    DataManager = Core:Get("DataManager")
    
end

function PurchaseManager:Start()


   
end

function PurchaseManager:PurchaseItem(Player, ItemData)

end


function PurchaseManager:PurchaseGamePass(Player, PassId)
    
end



return PurchaseManager