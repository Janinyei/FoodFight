--Purpose: Centralized remote hub for the client & server using Warp.
-- Note: Instead of having all Warp remotes be instantiated in different locations, this module serves to reduce any confusion
-- by making all events viewable at once, and loads them at start time.
--janin 10/26/25

local SharedRemotes = {}
function SharedRemotes:Init()
	self.RemoteNames = {
		"DataEvent",
		"CurrencyEvent",
        "InventoryEvent",
		"ProjectileEvent",
		"TimerEvent",
		"ProgressionEvent",
		"VFXEvent",
		"GameStatusEvent",
		"CombatEvent",
		"CharacterEvent",
		"StatusEffectEvent",
		"AudioEvent",
		"VoteEvent",
		"LeaderboardEvent",
		"DeathEvent",
		"SpectateEvent"
	}

	self.Events = nil

	local Warp = require(script.Parent.Parent.Parent.Utils.Warp)
	local RunService = game:GetService("RunService")

	if RunService:IsServer() then
		self.Events = Warp.fromServerArray(self.RemoteNames) --loads on server
	elseif RunService:IsClient() then
		self.Events = Warp.fromClientArray(self.RemoteNames) --loads on client
	end

	print("shared remotes initiated")
end

function SharedRemotes:GetEvent(EventName: string)
	if self.Events[EventName] then
		return self.Events[EventName]
	else
		warn("Called event '", EventName, "' does not exist")
	end
	return nil
end

--Use case:
--[[
Connection:
SharedRemotes.Events.DataEvent:Connect(function()

end)
------------------------------------------
Firing:
SharedRemotes.Events.DataEvent:Fire()
]]

return SharedRemotes
