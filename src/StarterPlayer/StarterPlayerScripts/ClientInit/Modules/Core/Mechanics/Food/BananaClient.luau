--purpose: food module for combat
--janin 12/10/25
--important: remember, this is a client side ONLY script. The only reason why it's here in rep storage is to replicate vfx.

local BananaClient = {}

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





function BananaClient:Init(Core)
	self.ProjectileController = Core:Get("ProjectileController")
	self.Config = require(ReplicatedStorage.Modules.Info.FoodCombatConfigs.BananaConfig)
	self.VFXController = Core:Get("VFXController")
	self.FoodCombatController = Core:Get("FoodCombatController")
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")
end

function BananaClient:OnFire()
print("custom banana on fire stuff that's additional, not overriding")
end


function BananaClient:Start() end


--Replication Functions--

function BananaClient:FireReplicated(data)
	local ProjectileConfig = self.Config.Projectile

	local DebugPart = Instance.new("Part")
	DebugPart.Anchored = false
	DebugPart.CanQuery = false
	DebugPart.CanCollide = false
	DebugPart.Color = Color3.fromRGB(40, 255, 183)
	DebugPart.Size = Vector3.one * 4
	DebugPart.Transparency = 0.5

	
	local RayParams = RaycastParams.new()
	RayParams.FilterDescendantsInstances = { self.ProjectileController.AlwaysExcludedInstances, data.Sender.Character }
	RayParams.FilterType = Enum.RaycastFilterType.Exclude

	print(data.Projectile)
	local RepProj = self.ProjectileController:FireProjectile(DebugPart, data.Projectile)

	
end

function BananaClient:OnHit(player, data)
	
	self:_PlayHitVFX(data)

	
end


--Custom Actions
function BananaClient:HandleAction(action,  data)

end

function BananaClient:OnHitReplicated(data)
self:_PlayHitVFX(data)
end


--helpers--
 function BananaClient:_PlayHitVFX(data)

	--[[self.VFXController:PlayEffect("FoodSplat", {
			Position = data.Projectile.HitResult.Position,
			Normal = data.Projectile.HitResult.Normal,
			Obj = data.Projectile.HitResult.Instance,
			FoodName = data.Combat.FoodName,
			Color = Color3.fromRGB(255, 255, 135),
			Radius = 3,
		})]]

		--instead of using the food splat use a blunt effect for banana impact

	
end



return BananaClient
