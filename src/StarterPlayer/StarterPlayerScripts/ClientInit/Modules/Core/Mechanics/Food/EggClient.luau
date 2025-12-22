--purpose: food module for combat
--janin 12/10/25
--important: remember, this is a client side ONLY script. The only reason why it's here in rep storage is to replicate vfx.

local EggClient = {}

--Services--
local Debris = game.Debris
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--Modules--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils
local EffectsModules = Modules.Effects
--Imports--
local Functions = require(Utils.Functions)
local FoodSplat = require(EffectsModules.FoodSplat)

--Variables--
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local FoodModels = ReplicatedStorage.Assets.FoodModels


--helpers--

local function getSpreadDirection(baseDir: Vector3, maxAngleDeg: number): Vector3
	-- maxAngleDeg: how wide the spread cone is, e.g. 5–10 degrees
	
	-- Build an orthonormal basis around baseDir
	local dir = baseDir.Unit
	-- Pick an arbitrary vector that's not parallel to dir
	local arbitrary = math.abs(dir.Y) < 0.99 and Vector3.yAxis or Vector3.xAxis
	
	local right = dir:Cross(arbitrary).Unit
	local up = right:Cross(dir).Unit
	
	-- Random small angles
	local angleRad = math.rad(maxAngleDeg)
	local offsetX = math.random(-100, 100) / 100 * math.tan(angleRad)
	local offsetY = math.random(-100, 100) / 100 * math.tan(angleRad)
	
	-- New direction in local frame: dir + offsetX * right + offsetY * up
	local newDir = (dir + right * offsetX + up * offsetY).Unit
	return newDir
end

function EggClient:Init(Core)
	self.ProjectileController = Core:Get("ProjectileController")
	self.Config = require(ReplicatedStorage.Modules.Info.FoodCombatConfigs.EggConfig)
	self.VFXController = Core:Get("VFXController")
	self.FoodCombatController = Core:Get("FoodCombatController")
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")
end

function EggClient:Fire()
	--would prolly have to get projectilecontroller

	--test representation of custom firing functionality

	if self.FoodCombatController.UltimateActivated then
		for i = 1, 3 do
			self:ShootEgg(true)
			task.wait(0.01)
		end

		return --guard clause
	end

	self:ShootEgg()
end


--different form Fire, OnFire consists of additional functionality. If you want to overwrite the fire function, then use Fire instead in the client module
function EggClient:OnFire(data)
	--use for vfx possibily
end

function EggClient:ShootEgg(Spread: boolean?)
	local ProjectileConfig = self.Config.Projectile
	local Velo = (Mouse.Hit.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * ProjectileConfig.Speed
		+ ProjectileConfig.InitUpwardVelocity

	if Spread then
		--[[local dirCF =  CFrame.new(Vector3.zero, Velo.Unit)
			local spreadDirection = CFrame.Angles(0,0, math.random(0, math.pi ))
			local spreadAngle = CFrame.Angles(math.random(0, math.pi), 0, 0)
			local newDir = (dirCF * spreadDirection * spreadAngle).LookVector
		
			Velo = newDir * ProjectileConfig.Speed
		]]
	

		--cross product approach

		

		Velo = (getSpreadDirection(Velo.Unit, 5)) * ProjectileConfig.Speed 
	end

	local NewProj = self.ProjectileController:FireProjectile(FoodModels.Egg:Clone(), {
		Owner = LocalPlayer,
		Id = self.ProjectileController:GenerateProjectileId(LocalPlayer),
		RaycastParams = self.ProjectileController.RaycastParams,
		Origin = LocalPlayer.Character.HumanoidRootPart.Position,
		Velocity = Velo,
		Acceleration = ProjectileConfig.Acceleration,
		MaxBounces = ProjectileConfig.MaxBounces,
		Restitution = ProjectileConfig.Restitution,
		Update = self.Update,
		isReplicated = false,
	})

	--Fire to server--
	self.CombatEvent:Fire(true, "Fire", {
		Sender = LocalPlayer,
		Combat = {
			FoodName = "Egg",
			
		},

		Projectile = {
			Id = NewProj.Id,
			Owner = LocalPlayer,
			Origin = NewProj.Position,
			Velocity = NewProj.Velocity,
			Timestamp = tick(),
		},
	})

	--run onhit event--
	NewProj.OnHit:Connect(function(hitResult)
		self:OnHit({


			Combat = {

				FoodName = "Egg",
			},

			Projectile = {
				Id = NewProj.Id,
				Velocity = NewProj.Velocity,
				HitResult = {
					Instance = hitResult.Instance,
					Position = hitResult.Position,
					Normal = hitResult.Normal,
				},
				CanBounce = (NewProj.BounceCount >= 1),
			},
		})
	end)
end

function EggClient:Start() end

function EggClient:OnHit(data)


--	local dist = math.clamp((hrp.Position - Epicenter).Magnitude, 0.1, 9999999)
--	local dir = (hrp.Position - Epicenter).Unit
--	local ExplosiveForce = self.Config.Combat.BlastForce * hrp.AssemblyMass * (1 / dist ^ 2)
	--LocalPlayer.Character.HumanoidRootPart:ApplyImpulse(dir * ExplosiveForce)

	if self.FoodCombatController.UltimateActivated then
			self:ChickenSpawnVFX(data)
		else
			self:PlayEggHitVFX(data)
	end

	--fire to the server for replication--

	self.CombatEvent:Fire(true, "Hit", {
		Sender = LocalPlayer,
		Combat = {
			FoodName = "Egg",
			Ultimate = self.FoodCombatController.UltimateActivated
		},
		Projectile = {
			Id = data.Projectile.Id,
			Velocity = data.Projectile.Velocity,
			Position = data.Projectile.HitResult.Position,

			HitResult = {
				Instance = data.Projectile.HitResult.Instance,
				Position = data.Projectile.HitResult.Position,
				Normal = data.Projectile.HitResult.Normal,
			},
		},
	})
end

--Replication Functions--



function EggClient:FireReplicated(data)
	local ProjectileConfig = self.Config.Projectile

	local DebugPart = Instance.new("Part")
	DebugPart.Anchored = false
	DebugPart.CanQuery = false
	DebugPart.CanCollide = false
	DebugPart.Color = Color3.fromRGB(40, 255, 183)
	DebugPart.Size = Vector3.one * 4
	DebugPart.Transparency = 0.5

	--[[
	concern:the projectile is supposed to ignore the person who shot it, but since we're using another persons' raycast params, 
	our client may still register hits made on them by their own projectile, which isn't supposed to happen. 

	goal: we need a way to nullify object collision with the shooter on others' clients

	solution(s):
	- simply create a new raycast param
	-temporarily add plr to blacklist(bad because projectiles that are actually supposed to hit wouldn't detect so don't do this lol)
	
	]]
	
	local RepProj = self.ProjectileController:FireProjectile(DebugPart, {
		Owner = data.Sender,
		Id = data.Projectile.Id,
		
		Origin = data.Sender.Character.HumanoidRootPart.Position,
		Velocity = data.Projectile.Velocity,
		Acceleration = ProjectileConfig.Acceleration,
		MaxBounces = ProjectileConfig.MaxBounces,
		Restitution = ProjectileConfig.Restitution,
		Update = self.Update,
		isReplicated = true,
	})

	
end


--Custom Actions
function EggClient:HandleAction(action,  data)
	if action == "ChickenCleanup" then
		
			self.VFXController:PlayEffect("PoofClouds", {
				Position = data.Position
			})
	
	end
end
function EggClient:OnHitReplicated(data)
	--get the replicated projectile
	local RepProj = self.ProjectileController:GetProjectile(data.Projectile.Id)
	--RepProj.Position = data.Projectile.Position

	
	if data.Combat.Ultimate then
		self:ChickenSpawnVFX(data)
	else
		self:PlayEggHitVFX(data)
	end
end

function EggClient:Update() end

--Misc / VFX --

function EggClient:ExplosionForce(Epicenter: Vector3) end



function EggClient:PlayEggHitVFX(data)
	--show some vfx--

	local EggEffects = ReplicatedStorage.Assets.Food.Egg
	local EggVFXFolder = EggEffects.Visual

	local EggSplash = EggVFXFolder.EggSplash:Clone()
	EggSplash.Position = data.Projectile.HitResult.Position
	EggSplash.Parent = workspace.VisualEffectsCache
	Debris:AddItem(EggSplash, 5)

	Functions.Emit(EggSplash)

	self.VFXController:PlayEffect("FoodSplat", {
		Position = data.Projectile.HitResult.Position,
		Normal = data.Projectile.HitResult.Normal,
		Obj = data.Projectile.HitResult.Instance,
		FoodName = data.Combat.FoodName,
		Color = Color3.fromRGB(227, 251, 198),
		Radius = 10,
	})
end

function EggClient:ChickenSpawnVFX(data)
	local EggEffects = ReplicatedStorage.Assets.Food.Egg
	local EggVFXFolder = EggEffects.Visual

	self.VFXController:PlayEffect("PoofClouds", {Position = data.Projectile.HitResult.Position})
end

function EggClient:Ultimate() end

return EggClient
