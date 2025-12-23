--purpose: enforce status effects to players
--janin 12/22/25

--status effects: ragdoll, burning(chili pepper), frozen(ice cream),

local StatusEffectManager = {}

local ReplicatedStorage = game:GetService("ReplicatedFirst")

local Modules = ReplicatedStorage.Modules
local Signal = require(Modules.Utils.Signal)

function StatusEffectManager:Init(Core)
	--[[

    
    ]]

	self.EffectedPlayers = {
		--  [player1] = {"Burning", "Ragdoll"}
}

	self.StatusEffectEvent = Core:Get("SharedRemotes"):GetEvent("StatusEffectEvent")
	self.StatusEffectApplied = Signal.new()
end

function StatusEffectManager:ApplyEffect(plr: Player, effectName: string)
	local effectTable
	if self.EffectedPlayers[plr] then
		effectTable = self.EffectedPlayers[plr]
	else
		self.EffectedPlayers[plr] = {}
		--create new one if not already there
		effectTable = self.EffectedPlayers[plr]
	end

	if table.find(effectTable, effectName) ~= nil then
		return
	end

	table.insert(effectTable, effectName)

    self.StatusEffectApplied:Fire(effectName)
    self.StatusEffectEvent:Fire(true, plr, effectName)
end


--private--

function StatusEffectManager:HasEffect(plr: Player, effectName: string)
    local effectTable = self.EffectedPlayers[plr]
    
	if table.find(effectTable, effectName) ~= nil then
		return true
	end
	return false
end

return StatusEffectManager
