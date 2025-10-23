export type ProjectileObject = {
    Type : string,
    Model : Model,
    Name : string,
    InitialVelocity : Vector3,
}

--Purpose: Create Projectile Objects to be used by the Projectile Controller
--janin 10/22/25

--Services--
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--Modules--
local Modules = ReplicatedStorage.Modules
local NetRay = require(Modules.NetRay) --replication stuff

local Projectile = {}


--Projectile Class
function  Projectile.new(Type : string, Name : string?, Model : Model)
    local self = setmetatable({}, Projectile)
    self.Type  = Type --Blast, Normal, etc
    self.Model = Model or nil --be sure that the model is massless 
    self.Name = Name or "Projectile"
    self.InitialVelocity = Vector3.zero
    self.Active = false
end

function Projectile:Fire(InitialVelocity : Vector3)
    self.InitialVelocity = InitialVelocity
    if self.Model then
        self.Model:SetPrimaryPartCFrame(self.Model.PrimaryPart.CFrame * CFrame.new(0, 0, -1))
    end
--use network module to fire to server--

end

function  Projectile:Pause()
    self.Active = false
end

function  Projectile:Terminate()
    if self.Model then
        self.Model:Destroy()
    end
    self.Active = false
end


return Projectile