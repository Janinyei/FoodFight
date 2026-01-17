--purpose: handles replication of kill effects on all clients
--note: you can try to use settings part of the datamanager to blacklist players who don't want kill effects being replicated to them

local DeathController = {}

local Players = game.Players
local LocalPlayer = Players.LocalPlayer
local KillEffectsFolder = game.ReplicatedStorage.Modules.KillEffects

function DeathController:Init(Core)
	self.VFXController = Core:Get("VFXController")
	self.DeathEvent = Core:Get("SharedRemotes"):GetEvent("DeathEvent")
	self.KillcamController = Core:Get("KillcamController")
	self.CameraController = Core:Get("CameraController")
end

function DeathController:Start(Core)
	self.DeathEvent:Connect(function(eliminationData)
		local targetPlayer = eliminationData.Victim
		if targetPlayer == LocalPlayer then
			self.CameraController:Spectate(eliminationData.Corpse)
		end

		self:PlayKillEffect(eliminationData.KillEffect, {
			TargetCharacter = eliminationData.Corpse,
			Killer = eliminationData and eliminationData.Killer,
			Victim = eliminationData and eliminationData.Victim,
		}, Core)



		--handle kill feed gui here
--[[
self.KillfeedGui:AddKill(eliminationData)
]]
		--kill cam

		if targetPlayer == LocalPlayer then
			task.delay(0.5, function() --transition to killcam
				self.KillcamController:StartKillcam(eliminationData.Killer)
			end)
			--handle self kill message or smtn idk
		end
	end)
end

function DeathController:PlayKillEffect(effectName: string, data, Core)
	local effectModule = KillEffectsFolder:FindFirstChild(effectName)
	if not effectModule then
		local lowered = string.lower(effectName)
		for _, child in KillEffectsFolder:GetChildren() do
			if string.lower(child.Name) == lowered then
				effectModule = child
				break
			end
		end
	end

	if effectModule then
		require(effectModule):PlayKillEffect(data, Core)
	end
end

return DeathController
