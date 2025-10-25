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


function Init()
    DataManager = Core:Get("DataManager")
end

function  PurchaseManager:Start()
    --init remote functions that listen to different 'types' of events
        --when I say types I mean like "Skin" or "Food" 
end

function PurchaseManager:PurchaseFood(Name : string)
    
end

return PurchaseManager