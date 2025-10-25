--Purpose: To help simuate the client-sided projectile physics
--janin 10/22/25
--[[
Design:
Player triggers projectile 
Game Checks if cooldown is active 
If it's not, then 
    Game creates a new projectile
    Game adds the projectile to the table of projectiles
    Game sets the cooldown active
    Game Fires an event to the server to do projectile hit calculations
    Other Clients recieve the visual event
notes:
since projectiles can use different models/foods, I need to figure out a way to simply set the model of the fruit to the projectile


]]



--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CAS = game:GetService("ContextActionService")

--Modules--
local Modules = ReplicatedStorage.Modules
local Core = require(Modules.Core)
local Utils = Modules.Utils
local Warp = require(Utils.Warp)
local Projectile = require(script.Projectile)
--Variables--
local Player = Players.LocalPlayer

--Classes or smtn idk
local ProjectileController = {}


--Projectile Controller Methods
function ProjectileController:Init()
    self.Projectiles = {}
    self.FoodMetaData = require(Modules.Info.FoodMetaData)
end

function  ProjectileController:Start()
    --whenever someone clicks, create and fire a projectile
    local fireAction = "FireProjectile"
    local function fireProj(inputObject, inputState)
        if inputState == Enum.UserInputState.Begin then
            local NewProj = Projectile.new("Normal", "TestProjectile")
            NewProj:Fire()
            self:AddProjectile(NewProj)
        end
    end

    CAS:BindAction(fireAction, fireProj, false, Enum.UserInputType.MouseButton1)
      --setup replication event here to recieve visual effects and such
end


function ProjectileController:GetProjectileData(Name : string)
    return self.FoodMetaData[Name]
end


function ProjectileController:AddProjectile(Proj : Projectile.ProjectileObject)
    table.insert(self.Projectiles, Proj)
end

function  ProjectileController:RemoveProjectile(Proj : Projectile.ProjectileObject)
    for i, v in ipairs(self.Projectiles) do
        if v == Proj then
            table.remove(self.Projectiles, i)
            break
        end
    end
end

return ProjectileController