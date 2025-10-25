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
local ProjectileController = {}


--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

--Modules--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils
--Imports--
local Warp = require(Utils.Warp)
local Projectile = require(script.Projectile)

--Data--
local FoodIndex = require(Modules.Info.FoodIndex)

--Variables--
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--Constants--
local GRAVITY = Vector3.new(0,-50,0)
local MAX_PROJECTILE_LIFETIME = 10
local RAYCAST_DISTANCE = 1
local MAX_DISTANCE_ALLOWED = 300


--Projectile Controller Methods
function ProjectileController:Init()
     self.Projectiles = {} --Sets up container for physics
     self.RaycastParams = RaycastParams.new()
     self.RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
     self.RaycastParams.FilterDescendantsInstances = {}
     self.ProjectileCooldowns = {}
     self.ProjectileEvent = Warp.Client("ProjectileEvent")
end

function ProjectileController:Start()
    --whenever someone clicks, create and fire a projectile
    local fireAction = "FireProjectile"
    
    local function fireProj(inputObject, inputState)

        if inputState == Enum.UserInputState.End then
           self:AttemptFire("Burger")
        end
    end

    CAS:BindAction(fireAction, fireProj, false, Enum.UserInputType.MouseButton1)
      --setup replication event here to receive visual effects and such
      self:StartReplicationListener()
      --setup physics sim
      self:StartPhysicsSim()
end


function ProjectileController:AddProjectile(proj)
self.Projectiles[proj.Id] = proj
end

function  ProjectileController:RemoveProjectile(id)
   local proj = self.Projectiles[id]
   if proj then
    proj:Cleanup()
    self.Projectiles[id] = nil
   end
end


function ProjectileController:AttemptFire(FoodName : string)
    --check character instances
     if LocalPlayer.Character == nil  then return end --guard clause
        local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
     if not HRP then return end --guard clause
     --check cooldowns
     local currentTime = tick()
     local foodData = FoodIndex[FoodName] or  {HitBehavior = "Normal", BaseDamage = 10, Cooldown = 1}
     local cooldown = foodData.Cooldown

     if self.ProjectileCooldowns[FoodName] and currentTime - self.ProjectileCooldowns[FoodName] < cooldown then return end --another guard clause
        --define launch parameters
            local Direction = Camera.CFrame.LookVector --direction the player aiming
            local Speed = 100
            local Velocity = Direction * Speed
            local Origin = HRP.Position + HRP.CFrame.LookVector * 5
       
            local ProjectileId = self:GenerateProjectileId()


            --create & fire projectile
            local NewProj = Projectile.new({
             Id = ProjectileId,
            FoodName = FoodName,
            Origin = Origin,
            Velocity = Velocity,
            Owner = LocalPlayer,
            Restitution = foodData.Restitution or 0.5,
            Gravity = GRAVITY,
            MaxBounces = foodData.MaxBounces or 0,
            Damage = foodData.Damage or 10,
            Special = foodData.Special or {}
                })

            NewProj:Fire(Origin, Velocity)
            self:AddProjectile(NewProj)

            self.ProjectileCooldowns[FoodName] = currentTime

            self.ProjectileEvent:Fire(true,{
                Id = ProjectileId,
                FoodName = FoodName,
                Origin = Origin,
                Direction = Direction,
                Timestamp = currentTime
            })
end

function  ProjectileController:StartPhysicsSim()
    self.PhysicsConnection = RunService.Heartbeat:Connect(function(deltaTime)
        local currentTime = tick()

        --blacklist
        local blacklist = {LocalPlayer.Character}
        for _, proj in pairs(self.Projectiles) do
            if proj.Model then
                table.insert(blacklist, proj.Model)
            end
        end

        self.RaycastParams.FilterDescendantsInstances = blacklist
        
        --handle each projectile

        for id, proj in pairs(self.Projectiles) do
            --check lifetime
            if currentTime - proj.StartTime > MAX_PROJECTILE_LIFETIME then
                self:RemoveProjectile(proj)
                continue
            end

            --Store previous position for raycasting
            local prevPos = proj.Position
            

            --Update physics

            proj:UpdatePhysics(deltaTime)

            --hit detection
            local hitResult = self:CheckHit(prevPos, proj.Position, proj)

            if hitResult then
                self:HandleHit(proj, hitResult)
            end

            --check if it's too far away
          --  if (proj.Position - proj.Origin).Magnitude > MAX_DISTANCE_ALLOWED then
           --     self:RemoveProjectile(id)
          --  end
        end
    end)
end

function ProjectileController:CheckHit(startPos, endPos, projectile)
    local direction =  (endPos - startPos)
    local distance = direction.Magnitude

    if distance <= 0 then return nil end

    local raycast = workspace:Raycast(
        startPos, 
        direction.Unit * (distance + RAYCAST_DISTANCE),
        self.RaycastParams
    )

    return raycast
end

function ProjectileController:HandleHit(projectile, hitResult : RaycastResult)
    local hitInstance = hitResult.Instance
    local hitNormal = hitResult.Normal
    local hitPos = hitResult.Position

    --check if it hits a player
    local humanoid = hitInstance.Parent:FindFirstChildOfClass("Humanoid")
    if humanoid and hitInstance.Parent ~= LocalPlayer.Character then
        --let server validate(fire remote to server here)
        return --end func here
    end

    --bouncing

    if projectile.BounceCount < projectile.MaxBounces then
        projectile:Bounce(hitNormal, projectile.Restitution)
        projectile.BounceCount += 1
    else
        self:RemoveProjectile(projectile.Id)
    end
end

function ProjectileController:StartReplicationListener()

end

function ProjectileController:GenerateProjectileId()
    return LocalPlayer.Name .. HttpService:GenerateGUID(false)
end


return ProjectileController