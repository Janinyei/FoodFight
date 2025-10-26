--Purpose: Create Projectile Objects to be used by the Projectile Controller
--janin 10/22/25


export type ProjectileType = {
	Id: string,
	FoodName: string,
	Origin: Vector3,
	Velocity: Vector3,
	Owner: Player,
	Restitution: number?,
	Gravity: Vector3?,
	MaxBounces: number?,
	Damage: number?,
	IsReplicated: boolean?,
}

local Projectile = {}
Projectile.__index = Projectile

--Services--
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Modules--
local Modules = ReplicatedStorage.Modules

--Imports--
local Warp = require(Modules.Utils.Warp) --replication stuff

--Variables--
local FoodModels = ReplicatedStorage.Assets.FoodModels

local ProjectileFolder = Instance.new("Folder")
ProjectileFolder.Name = "Projectiles"
ProjectileFolder.Parent = workspace

--Projectile Class
function Projectile.new(data)
	local self = setmetatable({}, Projectile)

	--core properties
	self.Id = data.Id
	self.FoodName = data.FoodName
	self.Origin = data.Origin
	self.Position = data.Origin
	self.Velocity = data.Velocity
	self.Owner = data.Owner
	self.IsReplicated = data.IsReplicated or false
	--physical properties
	self.Restitution = data.Restitution or 0.5
	self.Gravity = data.Gravity or Vector3.new(0, -50, 0)
	self.MaxBounces = data.MaxBounces or 0
	self.BounceCount = 0

	--combat properties
	self.Damage = data.Damage or 10
	self.Special = data.Special or {}

	--timing
	self.StartTime = tick()
	self.LastUpdateTime = self.StartTime

	--model
	self.Model  = nil
	self.BodyPosition = nil
	self.BodyVelocity = nil

	return self
end

function Projectile:CreateModel()
	local foodModel = FoodModels[self.FoodName]:Clone()

	if foodModel then
		self.Model = foodModel:Clone()
		self.Model.Name = "Projectile_" .. self.Id

		--make model non-collideable

		for _, obj in self.Model:GetDescendants() do
			if obj:IsA("BasePart") or obj:IsA("MeshPart") then
				obj.CanCollide = false
				obj.CanQuery = false
				obj.CanTouch = false
				obj.Massless = true
				obj.Anchored = true
			end
		end
		self.Model.Parent = ProjectileFolder
	else -- generates part if model doesn't exist
		warn("Model '", self.FoodName, "' doesn't exist, substituting with part")
		local part = Instance.new("Part")
		part.Name = "Projectile_" .. self.Id
		part.Size = Vector3.new(2, 2, 2)
		part.Shape = Enum.PartType.Ball
		part.Material = Enum.Material.Neon
		part.BrickColor = BrickColor.new("Bright red")
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true

		local model = Instance.new("Model")
		model.Name = "Projectile_" .. self.Id
		model.PrimaryPart = part
		part.Parent = model

		self.Model = model
		self.Model.Parent = workspace.Projectiles
	end
end

function Projectile:UpdatePhysics(deltaTime)
	--Applying physics

	--apply gravity
	self.Velocity = self.Velocity + (self.Gravity * deltaTime)

	--changing position
	self.Position = self.Position + (self.Velocity * deltaTime)

	--use visual model
	if self.Model then
		self.Model:PivotTo(CFrame.lookAt(self.Position, self.Position + self.Velocity))
	end

	--debug part
	local part = Instance.new("Part")
	part.Parent = workspace.debugParts
	part.Position = self.Position - self.Gravity * deltaTime
	part.Size = Vector3.new(3, 3, 3)
	part.CFrame = CFrame.lookAlong(part.Position, self.Position)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0.8
	game.Debris:AddItem(part, 10)
end

function Projectile:Fire(Origin : Vector3, Velocity : Vector3)
    self.Position = Origin
    self.Velocity = Velocity
end

function Projectile:Bounce(hitNormal: Vector3)
	self.Velocity = self.Velocity - (2 * self.Velocity:Dot(hitNormal) * hitNormal)
	self.Velocity *= self.Restitution
end

function Projectile:Cleanup()
	if self.Model then
        self.Model:Destroy()
	end
end


return Projectile
