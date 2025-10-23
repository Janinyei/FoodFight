local Core = require(game.ReplicatedStorage.Modules.Core)
local module = {}
--modules--
local DataManager

function module:Start() 
    DataManager = Core:Get("DataManager")
    print("TestModule Start")
    print(DataManager.Profiles)
end
return module