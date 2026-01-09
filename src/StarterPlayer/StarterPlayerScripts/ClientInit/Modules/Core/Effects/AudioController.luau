-- Purpose: manages playing audio on client
-- janin 1/9/26
local AudioController = {}

--services--
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local AudioConfig = require(game.ReplicatedStorage.Modules.Info.AudioConfig)

function AudioController:Init(Core)
	self.SharedRemotes = Core:Get("SharedRemotes")
	self.AudioEvent = self.SharedRemotes:GetEvent("AudioEvent")

	self.PlayingSoundTracks = {} 
	self.AudioConfig = AudioConfig
end

function AudioController:Start()
	self.AudioEvent:Connect(function(action, audioData)
		if action == "Play" then
			self:PlayAudio(audioData)
		elseif action == "Stop" then
			self:StopAudio(audioData)
		end
	end)



end

function AudioController:PlayAudio(audioData)
	if not audioData or not audioData.Name then return end
	
	local config = AudioConfig[audioData.Name]
	if not config then return end

	local Sound = Instance.new("Sound")
	Sound.SoundId = "rbxassetid://" .. config.Id
	Sound.Name = audioData.Name
	Sound.SoundGroup = config.SoundGroup
	Sound.Volume = config.Volume or 1
	Sound.Parent = audioData.Source or SoundService
	Sound.Looped = config.Looped or false
	Sound.RollOffMaxDistance = config.MaxDistance or 50
	Sound.RollOffMinDistance = config.RollOffMinDistance or 10

	Sound:Play()

	-- Replication logic
	if config.ShouldReplicate and not audioData.isReplicated then
		self.AudioEvent:Fire(true, "Play", audioData)
	end

	self.PlayingSoundTracks[Sound] = { Name = audioData.Name, ConfigData = config }

	-- 1. Automatic Management based on config
	if config.Duration then
		-- Only delay a stop if a Duration is explicitly provided
		local fadeTime = config.FadeOutTime or 0
		task.delay(math.max(0, config.Duration - fadeTime), function()
			if Sound and Sound.Parent then
				self:StopAudio(Sound)
			end
		end)
	end

	--naturally clean sup sounds without a set duration and no need to replicate it
	Sound.Ended:Connect(function()
		if self.PlayingSoundTracks[Sound] then
			self.PlayingSoundTracks[Sound] = nil
		end
		Sound:Destroy()
	end)
	return Sound
end

function AudioController:StopAudio(SoundInput: Sound | string)
	local function processStop(soundObj)
		local info = self.PlayingSoundTracks[soundObj]
		if not info then return end

		-- Check if we should fade or just stop instantly
		local fadeTime = info.ConfigData.FadeOutTime
		
		if fadeTime and fadeTime > 0 then
			-- Logic for Fading Out
			local originalVolume = soundObj.Volume
			local tween = TweenService:Create(soundObj, TweenInfo.new(fadeTime), { Volume = 0 })
			
			tween.Completed:Connect(function()
				if soundObj.Parent and soundObj.Looped then
					soundObj.Volume = originalVolume
					return
				end
				self.PlayingSoundTracks[soundObj] = nil
				soundObj:Stop()
				soundObj:Destroy()
			end)
			tween:Play()
		else
			
			self.PlayingSoundTracks[soundObj] = nil
			soundObj:Stop()
			soundObj:Destroy()
		end
	end

	if typeof(SoundInput) == "Instance" and SoundInput:IsA("Sound") then
		processStop(SoundInput)
	elseif typeof(SoundInput) == "string" then
		for soundObj, info in pairs(self.PlayingSoundTracks) do
			if info.Name == SoundInput then
				processStop(soundObj)
			end
		end
	end
end

return AudioController