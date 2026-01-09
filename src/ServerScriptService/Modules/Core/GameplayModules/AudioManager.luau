-- Purpose: Manages audio state replication and triggers to the client
-- janin 1/6/26

--playlist is global, don't plan on making local for now

--note: will later need to implement stop function

--services--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

--modules--
local Modules = ReplicatedStorage.Modules

local AudioManager = {}
local AudioConfig = require(Modules.Info.AudioConfig)

-- Initialized by your Core system
function AudioManager:Init(Core)
	self.Core = Core

	-- Fetch the remote event from your SharedRemotes service
	self.SharedRemotes = Core:Get("SharedRemotes")
	self.AudioEvent = self.SharedRemotes:GetEvent("AudioEvent")
	self.Playlist = {}
    self.CurrentSongTrack = nil

	-- self.SongTrackChanged = Signal.new() --could need this who knows
end

function AudioManager:Start()
	-- This runs once after all modules are initialized
	-- Good for starting default background ambiance if needed

	--setup event listener

	self.AudioEvent:Connect(function(player, action: string, audioData: {})
		if action == "Play" then
			local blackList = { player }
			self:PlayGlobalAudio(audioData, blackList)
		end
	end)


   -- self:PlayRandomSong("InGame")


    --set up player added event to let player onto playlist

    Players.PlayerAdded:Connect(function(player)  
        if self.CurrentSongTrack then
        self:PlayAudioSpecificPlayer({Name = self.CurrentSongTrack})
        end
    end)


end

--plays audio for all players
function AudioManager:PlayGlobalAudio(audioData, blackList: { Player }?)
	print("replicating")
	local blackList = blackList or {}
	self.AudioEvent:FireExcept(true, blackList, "Play", { Name = audioData.Name, isReplicated = true })

end


function AudioManager:PlayAudioSpecificPlayer(audioData, targetPlayer : Player)
    self.AudioEvent:Fire(true, "Play", {Name = audioData.Name, isReplicated = true})
end

function AudioManager:StopAudio(audioData, blackList: { Player }?)
	print("replicating stop")
	local blackList = blackList or {}
	self.AudioEvent:FireExcept(true, blackList, "Stop", { Name = audioData.Name })
end

function AudioManager:PlayRandomSong(soundGroup: string)
	local SongsFromSoundGroup = self:_getSongNamesFromSoundGroup(soundGroup)

	local randIndex = math.random(1, #SongsFromSoundGroup)
	local randSong = SongsFromSoundGroup[randIndex]
    self.CurrentSongTrack = randSong

    task.delay(6, function()
        AudioManager:PlayGlobalAudio({ Name = randSong })
    end)
 
end

--priv
function AudioManager:_getSongNamesFromSoundGroup(SoundGroupName : string)
	local tbl = {}

    local SoundGroup = nil
    
    for _, sg in SoundService:GetDescendants() do
        if sg:IsA("SoundGroup") and sg.Name == SoundGroupName then 
             SoundGroup = sg
        end
    end


	if not SoundGroup then
		warn("sound group doesn't exist")
		return
	end


	--algo starts with one base sound group
	--loops through entire config to check for matches
    --if includeDescendants is true, then also checks if the set sound group is a descendant of the base sound group and includes it in the audio table as well

    --loop through config

    for audioName, audioData in AudioConfig do
        if audioData.SoundGroup == SoundGroup --[[or (includeDescendants and audioData.SoundGroup:IsDescendantOf(SoundGroup))]] then
            table.insert(tbl, audioName)
        end
    end

    print(tbl)
	return tbl
end

return AudioManager
