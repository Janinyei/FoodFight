--Purpose: Create Projectile Objects to be used by the Projectile Controller
--janin 10/22/25
--!nonstrict

export type ProjectileData = {
	Id: string?,
	Origin: Vector3,
	Velocity: Vector3,
	Owner: Player,
	Restitution: number?,
	Lifetime: number?,
	Acceleration: Vector3?,
	MaxBounces: number?,
	MaxDistance: number,
	Update: ((deltaTime: number, projectile: any) -> any)?,
	RaycastParams: RaycastParams,
	IsReplicated: boolean?
}

local Projectile = {}
Projectile.__index = Projectile

--Services--
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

--Modules--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils
local Signal = require(Utils.Signal)

--Constants--
local MAX_RAYCAST_DISTANCE = 1

--Variables--
local ProjectileFolder = Instance.new("Folder")
ProjectileFolder.Name = "Projectiles"
ProjectileFolder.Parent = workspace

local ActiveProjectiles = {}

-- Physics simulation heartbeat
RunService.Heartbeat:Connect(function(deltaTime)
	for id, proj in pairs(ActiveProjectiles) do
		if not proj.Active then 
			continue 
		end
		
		local CurrentTime = tick()
		
		-- Check lifetime
		if CurrentTime - proj.StartTime > proj.Lifetime then
			proj:Destroy()
			continue
		end
		
		-- Check max distance
		if (proj.Position - proj.Origin).Magnitude > proj.MaxDistance then
			proj:Destroy()
			continue
		end
		
		-- Use custom update function if provided
		if proj.Update then 
			proj.Update(deltaTime, proj)
		end
		
		-- Store previous position for raycasting
		local prevPos = proj.Position

		-- Update physics
		proj:UpdatePhysics(deltaTime)

		-- Hit detection
		local hitResult = proj:CheckHit(prevPos, proj.Position)
		if hitResult then
			-- Fire hit event
			proj.OnHit:Fire(hitResult)
			
			-- Handle bouncing
			if proj.BounceCount < proj.MaxBounces then
				proj:Bounce(hitResult.Normal)
				proj.BounceCount = proj.BounceCount + 1
			else
				-- Max bounces reached, destroy projectile
				proj:Destroy()
			end
		end
	end
end)

--Projectile Class
function Projectile.new(data: ProjectileData)
	local self = setmetatable({}, Projectile)
	
	-- Generate or use provided ID
	self.Id = data.Id or HttpService:GenerateGUID(false)

	-- Core properties
	self.Origin = data.Origin
	self.Position = data.Origin
	self.Velocity = data.Velocity
	self.Owner = data.Owner
	self.MaxDistance = data.MaxDistance or 9999
	self.Active = false
	self.Lifetime = data.Lifetime or 20
	self.IsReplicated = data.IsReplicated or false

	-- Physical properties
	self.Restitution = data.Restitution or 0.5
	self.Acceleration = data.Acceleration or Vector3.new(0, -50, 0)
	self.BounceCount = 0
	self.MaxBounces = data.MaxBounces or 0
	self.RaycastParams = data.RaycastParams or RaycastParams.new()
	
	-- Timing
	self.StartTime = tick()
	self.LastUpdateTime = self.StartTime
	
	-- Model
	self.Model = nil

	-- Events
	self.OnHit = Signal.new()
	self.OnDestroyed = Signal.new()
	
	-- Custom update function
	self.Update = data.Update
	
	return self
end

function Projectile:LoadModel(Model: Model | BasePart)
	if Model:IsA("Model") then 
		-- Handle Model type
		for _, obj in Model:GetDescendants() do 
			if obj:IsA("BasePart") or obj:IsA("MeshPart") then 
				obj.Anchored = true
				obj.CanCollide = false
				obj.CanQuery = false
				obj.CanTouch = false
			end
		end
		self.Model = Model
		self.Model.Parent = ProjectileFolder
		
	elseif Model:IsA("BasePart") then
		-- Handle single part
		Model.Anchored = true
		Model.CanCollide = false
		Model.CanQuery = false
		Model.CanTouch = false
		self.Model = Model
		self.Model.Parent = ProjectileFolder
	end
	
	-- Set initial position
	if self.Model then
		if self.Model:IsA("Model") then
			self.Model:PivotTo(CFrame.lookAt(self.Position, self.Position + self.Velocity))
		else
			self.Model.CFrame = CFrame.lookAt(self.Position, self.Position + self.Velocity)
		end
	end
end

function Projectile:UpdatePhysics(deltaTime: number)
	-- Apply acceleration (gravity)
	self.Velocity = self.Velocity + (self.Acceleration * deltaTime)
	
	-- Update position
	self.Position = self.Position + (self.Velocity * deltaTime)
	
	-- Update visual model
	if self.Model then
		local lookAtCFrame = CFrame.lookAt(self.Position, self.Position + self.Velocity)
		
		if self.Model:IsA("Model") then
			self.Model:PivotTo(lookAtCFrame)
		else
			self.Model.CFrame = lookAtCFrame
		end
	end
	
	self.LastUpdateTime = tick()
end

function Projectile:Fire()
	self.Active = true
	self.StartTime = tick()
	ActiveProjectiles[self.Id] = self
end

function Projectile:CheckHit(startPos: Vector3, endPos: Vector3)
	local direction = endPos - startPos
	local distance = direction.Magnitude
	
	if distance <= 0 then 
		return nil 
	end
	
	local raycast = workspace:Raycast(
		startPos, 
		direction.Unit * (distance + MAX_RAYCAST_DISTANCE),
		self.RaycastParams
	)
	
	return raycast
end

function Projectile:Bounce(hitNormal: Vector3)
	-- Reflect velocity off the surface
	self.Velocity = self.Velocity - (2 * self.Velocity:Dot(hitNormal) * hitNormal)
	
	-- Apply restitution (energy loss)
	self.Velocity = self.Velocity * self.Restitution
	
	-- Small upward boost to prevent sliding
	if math.abs(hitNormal.Y) > 0.7 then
		self.Position = self.Position + hitNormal * 0.1
	end
end

function Projectile:Stop()
	self.Active = false
end

function Projectile:Continue()
	self.Active = true
end

function Projectile:Destroy()
	-- Set inactive first
	self.Active = false
	
	-- Fire destroyed event
	self.OnDestroyed:Fire()
	
	-- Clean up model
	if self.Model then
		self.Model:Destroy()
		self.Model = nil
	end
	
	-- Remove from active projectiles
	ActiveProjectiles[self.Id] = nil
	
	-- Clean up signals
	self.OnHit:Destroy()
	self.OnDestroyed:Destroy()
end

-- Alias for backwards compatibility
function Projectile:Cleanup()
	self:Destroy()
end

return Projectile