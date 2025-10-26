--Purpose:  
--Handles projectile replication.
--Validates and handles sanity checks for projectiles(essentially anti-cheat)
--librium 10/26/25

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

    ProjectileEvent:Connect(function(player, action, data : {})
        if action == "Fire" then 
            print("replicating on server")
            ProjectileEvent:Fires(true, data)
        elseif action == "Hit" then
            --insert stuff
            print("hit")
        end
       
    end)
end

function  ProjectileManager:Start()
    
end

return ProjectileManager