--handles the grapes, replication, etc
local GrapesServer = {}

--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Imports--
local UtilFunctions = require(ReplicatedStorage.Modules.Utils.Functions)

function GrapesServer:Init(Core)
	self.ProjectileManager = Core:Get("ProjectileManager")
	self.Config = require(ReplicatedStorage.Modules.Info.FoodCombatConfigs.GrapesConfig)
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")
	self.FoodCombatManager = Core:Get("FoodCombatManager")
	self.EnergyManager = Core:Get("EnergyManager")
end

function GrapesServer:OnFireNormal(player, data)
	self.CombatEvent:FireExcept(true, { player }, "Fire", data)
end

function GrapesServer:OnHitNormal(player, data)
	local character = UtilFunctions.FindCharacter(data.Projectile.HitResult.Instance)
	if not character then
		return
	end

	self.FoodCombatManager:DamageCharacter(character, self.Config.Combat.BaseDamage, player)
end

function GrapesServer:OnFireUltimate(player, _)
	self.EnergyManager:Drain(player, self.Config.Energy.AbilityCost or 100)
end

function GrapesServer:OnHitUltimate(player, data)
	local character = UtilFunctions.FindCharacter(data.Projectile.HitResult.Instance)
	if character then
		self.FoodCombatManager:DamageCharacter(character, self.Config.Combat.UltimateDamage or self.Config.Combat.BaseDamage, player)
	end
end

return GrapesServer
