--handles the chicken npcs, replication, etc
--this code might have a memory leak lol

local BananaServer = {}

--Services--
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
--Imports--
local UtilFunctions = require(ReplicatedStorage.Modules.Utils.Functions)
local Hitbox = require(Modules.Utils.Hitbox)

function BananaServer:Init(Core)
	self.ProjectileManager = Core:Get("ProjectileManager")
	self.Config = require(ReplicatedStorage.Modules.Info.FoodCombatConfigs.BananaConfig)
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")
	self.FoodCombatManager = Core:Get("FoodCombatManager")
	self.EnergyManager = Core:Get("EnergyManager")
	self.StatusEffectManager = Core:Get("StatusEffectManager")
end

function BananaServer:OnFireNormal(player, data)
	self.CombatEvent:FireExcept(true, { player }, "Fire", data)
end

function BananaServer:OnHitNormal(player, data)
	local character = UtilFunctions.FindCharacter(data.Projectile.HitResult.Instance)
	if not character then
		return
	end

	self.FoodCombatManager:DamageCharacter(character, self.Config.Combat.BaseDamage, player)
end

function BananaServer:OnFireUltimate(player, data)
	self.EnergyManager:Drain(player, self.Config.Energy.AbilityCost or 100)
end

function BananaServer:OnHitUltimate(player, data)
	local character = UtilFunctions.FindCharacter(data.Projectile.HitResult.Instance)
	if character then
		self.FoodCombatManager:DamageCharacter(character, self.Config.Combat.UltimateDamage or self.Config.Combat.BaseDamage * 2, player)
	end

	self:SpawnBananaPeel(data, player)
end

--make a downwards ray to spawn on ground
function BananaServer:SpawnBananaPeel(data, owner)
	local RayOrigin = data.Projectile.HitResult.Position + data.Projectile.HitResult.Normal
	local RayDir = Vector3.yAxis * -4
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = { workspace.VisualEffectsCache }
	local PeelRay = workspace:Raycast(RayOrigin, RayDir)
	
	if not PeelRay then
		return
	end

	local BananaPeel = ReplicatedStorage.Assets.Food.Banana.BananaPeel:Clone()
	BananaPeel.Parent = workspace.VisualEffectsCache
	BananaPeel.CanQuery = false
	BananaPeel.CanCollide = false
	BananaPeel.Anchored = true
	BananaPeel.Position = PeelRay.Position + Vector3.yAxis * BananaPeel.Size.Y / 2

	Debris:AddItem(BananaPeel, 20)

	local BananaPeelHitbox = Hitbox.new()
	BananaPeelHitbox.DetectionMode = "Region"
	BananaPeelHitbox.Size = Vector3.one * 5
	BananaPeelHitbox.CFrame = CFrame.new(data.Projectile.HitResult.Position + Vector3.yAxis * BananaPeelHitbox.Size.Y / 2)
	BananaPeelHitbox.DebugMode = true

	BananaPeelHitbox:Start()

	BananaPeelHitbox.OnHit = function(hitData)
		local hitCharacter = hitData.Model
		local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
		
		if hitPlayer then
			self.StatusEffectManager:ApplyEffect(hitPlayer, "Ragdoll")
		end
		
		BananaPeelHitbox:Destroy()
	end
end

return BananaServer
