--Purpose: just a basic replicator for visual effects
--janin 10/29/25

local VFXReplicationManager = {}

function VFXReplicationManager:Init(Core)
    self.VFXEvent = Core:Get("SharedRemotes"):GetEvent("VFXEvent")
    
end


function VFXReplicationManager:Start()
    self.VFXEvent:Connect(function(Player : Player , data)
        print("from vfx replicator on server:")
        print(data)
        self.VFXEvent:FireExcept(true, {Player}, data)
    end)
end


return VFXReplicationManager