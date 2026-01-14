--purpose:
--note: you can try to use settings part of the datamanager to blacklist players who don't want kill effects being replicated to them

local KillEffectsManager = {}

function KillEffectsManager:Init(Core)
	self.CharacterManager = Core:Get("CharacterManager")

	self.KillEffectsEvent = Core:Get("SharedRemotes"):GetEvent("KillEffectsEvent")
	self.DataManager = Core:Get("DataManager")

	--
	self.CharacterDied = self.CharacterManager.CharacterDied

	
end

function KillEffectsManager:StartKillEffect(targetPlayer, eliminationData)
	warn("kill effects manager run")

	local killEffect = (
		eliminationData
		and eliminationData.Killer
		and self.DataManager:GetData(eliminationData.Killer).Inventory.Equipped.KillEffects
	) or self.DataManager:GetData(targetPlayer).Inventory.Equipped.KillEffects

	print(killEffect)
	self.KillEffectsEvent:Fires(true, targetPlayer, killEffect, eliminationData)
end

KillEffectsManager.Config = {
	["Blackhole"] = {
		Duration = 5,
	},
}

return KillEffectsManager
