--Purpose: Controls general purpose trail rendering & replication
-- janin: 12/6/25


local TrailsController = {}

--Serivces--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Modules--


--Variables--
local Assets = ReplicatedStorage.Assets
local TrailAssetsFolder = Assets.Trails




--prototype of what full trailsindex module will look like
local TrailsIndex = {
    ["Common"] = {
        "Basic"
    }
    --increases by rarity, crates will determine which kidns are unboxed
}

function TrailsController:Init(Core)
  --  self.ClientDataController = Core:Get("ClientDataController")
end

function TrailsController:Start()

end


function TrailsController:LoadTrail( TargetInstance : BasePart | Model)   
    if not TargetInstance then return end
    local BasicTrail = TrailAssetsFolder.Basic:Clone()
    BasicTrail.Parent = TargetInstance


    
end



return TrailsController