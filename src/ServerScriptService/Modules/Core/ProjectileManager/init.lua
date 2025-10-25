--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Modules--
local Modules = ReplicatedStorage.Modules

--Imports--
local Utils = Modules.Utils
local Warp = require(Utils.Warp)

--Events
local ProjectileEvent = Warp.Server("ProjectileEvent")

local ProjectileManager = {}



function ProjectileManager:Init()
    self.ActiveProjectiles = {}

    ProjectileEvent:Connect(function(player)
        print("projectile event received on server from ".. player.Name)
    end)
end

function  ProjectileManager:Start()
    
end

return ProjectileManager