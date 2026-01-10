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

	local isCritical = math.random() < 0.2
	local damage = self.Config.Combat.BaseDamage
	if isCritical then
		damage = damage * 2
	end

	local hitPart = data.Projectile and data.Projectile.HitResult and data.Projectile.HitResult.Instance
	local hitPos = data.Projectile and data.Projectile.HitResult and data.Projectile.HitResult.Position
	local isHeadshot = self.FoodCombatManager:IsHeadshot(character, hitPos, hitPart)
	if isHeadshot then
		print("[Headshot]", player.Name, "hit", character.Name)
	end

	self.FoodCombatManager:DamageCharacter(character, damage, player, {
		Critical = isCritical,
		Ultimate = false,
		FoodName = "Grapes",
		Headshot = isHeadshot
	})
end

function GrapesServer:OnFireUltimate(player, _)
	self.EnergyManager:Drain(player, self.Config.Energy.AbilityCost or 100)
end

function GrapesServer:OnHitUltimate(player, data)
	local character = UtilFunctions.FindCharacter(data.Projectile.HitResult.Instance)
	if character then
		local hitPart = data.Projectile and data.Projectile.HitResult and data.Projectile.HitResult.Instance
		local hitPos = data.Projectile and data.Projectile.HitResult and data.Projectile.HitResult.Position
		local isHeadshot = self.FoodCombatManager:IsHeadshot(character, hitPos, hitPart)
		if isHeadshot then
			print("[Headshot]", player.Name, "hit", character.Name)
		end

		self.FoodCombatManager:DamageCharacter(character, self.Config.Combat.UltimateDamage or self.Config.Combat.BaseDamage, player, {
			Critical = false,
			Ultimate = true,
			FoodName = "Grapes",
			Headshot = isHeadshot
		})
	end
end

return GrapesServer
