--purpose: handles replication of kill effects on all clients
--note: you can try to use settings part of the datamanager to blacklist players who don't want kill effects being replicated to them

local KillEffectController = {}

local Players = game.Players
local LocalPlayer = Players.LocalPlayer
local KillEffectsFolder = game.ReplicatedStorage.Modules.KillEffects


function KillEffectController:Init(Core)
	self.VFXController = Core:Get("VFXController")
	self.KillEffectsEvent = Core:Get("SharedRemotes"):GetEvent("KillEffectsEvent")
	self.KillcamController = Core:Get("KillcamController")

end

function KillEffectController:Start()
 
	self.KillEffectsEvent:Connect(function(targetPlayer, effectName: string, eliminationData)
        
   
		self:PlayKillEffect(effectName, {
			TargetPlayer = targetPlayer,
			Killer = eliminationData and  eliminationData.Killer,
		})

		if targetPlayer == LocalPlayer  and eliminationData and eliminationData.Killer then
			--play kill effect

			task.delay(5, function() --transition to killcam
				self.KillcamController:StartKillcam(eliminationData.Killer)
			end)
		end
	end)
end

function KillEffectController:PlayKillEffect(effectName: string, data)
	if KillEffectsFolder:FindFirstChild(effectName) then
		require(KillEffectsFolder[effectName]):PlayKillEffect(data)
	end
end

return KillEffectController
