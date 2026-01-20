local DonutServer = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UtilFunctions = require(ReplicatedStorage.Modules.Utils.Functions)

function DonutServer:Init(Core)
	self.Config = require(ReplicatedStorage.Modules.Info.FoodCombatConfigs.DonutConfig)
	self.FoodCombatManager = Core:Get("FoodCombatManager")
	self.EnergyManager = Core:Get("EnergyManager")
end

function DonutServer:OnHitNormal(player, data)
	local character = UtilFunctions.FindCharacter(data.Projectile.HitResult.Instance)
	if not character then
		return
	end

	local hitPart = data.Projectile and data.Projectile.HitResult and data.Projectile.HitResult.Instance
	local hitPos = data.Projectile and data.Projectile.HitResult and data.Projectile.HitResult.Position
	local isHeadshot = self.FoodCombatManager:IsHeadshot(character, hitPos, hitPart)

	self.FoodCombatManager:DamageCharacter(character, self.Config.Combat.BaseDamage, player, {
		Critical = false,
		Ultimate = false,
		FoodName = "Donut",
		Headshot = isHeadshot,
	})
end

function DonutServer:OnFireUltimate(player, _)
	self.EnergyManager:Drain(player, self.Config.Energy.AbilityCost or 100)
end

function DonutServer:OnHitUltimate(_, _)
end

return DonutServer
