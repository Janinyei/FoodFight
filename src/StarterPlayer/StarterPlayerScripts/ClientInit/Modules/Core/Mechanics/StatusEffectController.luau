--Purpose: Handles clint status effects
--Note: Listens for status effect changes from server

local StatusEffectController = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Modules.Utils.Signal)

function StatusEffectController:Init(Core)
	self.StatusEffectSignal = Signal.new()
	self.Effects = {}

	local StatusEffectEvent = Core:Get("SharedRemotes"):GetEvent("StatusEffectEvent")
	StatusEffectEvent:Connect(function(player, effectName, applied)
		if player == LocalPlayer then
			self.StatusEffectSignal:Fire(effectName, applied)
			self:_handleStatusEffect(effectName, applied)
		end
	end)
end

function StatusEffectController:_handleStatusEffect(effectName, applied)
	if effectName == "Ragdoll" and applied then
		print("ragdoll")
	end
end

--can check if you or someone else has an effect
function StatusEffectController:HasEffect(player, effectName: string)
	return (player ~= LocalPlayer) and self.StatusEffectEvent:Invoke(20, "HasEffect", effectName)
		or (table.find(self.Effects, effectName) ~= nil)
end

function StatusEffectController:OnStatusEffectApplied(callback)
	return self.StatusEffectSignal:Connect(callback)
end

return StatusEffectController
