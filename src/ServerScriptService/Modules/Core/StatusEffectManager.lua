--purpose: enforce status effects to players
--janin 12/22/25

--status effects: ragdoll, burning(chili pepper), frozen(ice cream),

local StatusEffectManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local Signal = require(Modules.Utils.Signal)

function StatusEffectManager:Init(Core)
	--[[

    
    ]]

	self.EffectedPlayers = {
		--  [player1] = {"Burning", "Ragdoll"}
}

	self.StatusEffectEvent = Core:Get("SharedRemotes"):GetEvent("StatusEffectEvent")

    --signals--
	self.StatusEffectApplied = Signal.new()
    self.StatusEffectRemoved = Signal.new()

end


function StatusEffectManager:Start()
    self.StatusEffectEvent:Connect(function(plr, action)
        
    end)
end

function StatusEffectManager:ApplyEffect(plr: Player, effectName: string)	
    local effectTable

	if self.EffectedPlayers[plr] then
		effectTable = self.EffectedPlayers[plr]
	else
		self.EffectedPlayers[plr] = {}
        effectTable = self.EffectedPlayers[plr]
	end

	if table.find(effectTable, effectName) ~= nil then
		return
	end

	table.insert(effectTable, effectName)

    self.StatusEffectApplied:Fire(plr, effectName)
    self.StatusEffectEvent:Fire(true, plr, effectName, true)
end

function StatusEffectManager:RemoveEffect(plr: Player, effectName: string)
    local effectTable = self.EffectedPlayers[plr]
    if not effectTable then return false end
    
    local index = table.find(effectTable, effectName)
    if index then
        table.remove(effectTable, index)

        self.StatusEffectRemoved:Fire(plr, effectName)
        self.StatusEffectEvent:Fire(true, plr, effectName, false)

        return true
    end
    
    return false
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
