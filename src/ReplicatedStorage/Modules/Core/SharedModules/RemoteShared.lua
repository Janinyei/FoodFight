--Purpose: Centralized remote hub for the client & server using Warp. 
-- Note: Instead of having all Warp remotes be instantiated in different locations, this module serves to reduce any confusion
-- by making all events viewable at once, and loads them at start time.


local RemoteShared = {}
function RemoteShared:Init()
    print("initalize remote shared")
    self.RemoteNames = {
        "DataEvent",    
    }

    self.Events  = nil


    local Warp = require(script.Parent.Parent.Parent.Utils.Warp)
    local RunService = game:GetService("RunService")
    
    if RunService:IsServer() then 
       self.Events =  Warp.fromServerArray(self.RemoteNames) --loads on server
    elseif RunService:IsClient() then
       self.Events = Warp.fromClientArray(self.RemoteNames) --loads on client
    end
end

--Use case:
--[[
Connection:
RemoteShared.Events.DataEvent:Connect(function()

end)
------------------------------------------
Firing:
RemoteShared.Events.DataEvent:Fire()
]]

return RemoteShared