--holds all audio info/data

local SoundService = game.SoundService

--sound groups--

--music sound groups--
local MusicSoundGroup = SoundService.Music
local InGame = MusicSoundGroup.InGame

--sound effects--

local SoundEffectsGroup = SoundService:FindFirstChild("SoundEffects")
local CharacterSounds = SoundEffectsGroup.CharacterSounds
local ParkourSounds = CharacterSounds.Parkour
local Intermission = SoundService.Music.Intermission

--audio data:
--[[
Volume : number
SoundGroup : SoundGroup
Id : string
Duration : number
FadeOutTime : number
Looped : boolean
ShouldReplicate : boolean
MaxDistance : number --literally RollOffMaxDistance
MinDistance : number --literally RollOffMinDistance

]]

--you can change some stuff using the sound groups in the explorer if you need

local AudioConfig = {

	----------------[AUDIO TRACKS]------------------

	--In game music --
	["podiumsong1"] = {
		Id = "1846703675",
		SoundGroup = InGame, --sound group instance
		Duration = 10, --lifetime
		FadeOutTime = 6, -- time it takes for a song to fade out. Works by fading out at the (duration - fadeOutTime) and playing a tween for the same amount of time of the fadeOutTime
		--	Looped = true,
		--	ShouldReplicate = true,
	},

	["lobby song"] = {
		Id = "1839824117",
		SoundGroup = Intermission,
		FadeOutTime = 4,
	},

	--movement audio--

	["vault"] = {
		Id = "98683346736585",
		SoundGroup = ParkourSounds,
		ShouldReplicate = true,
	},

	["slideenter"] = {
		Id = "97251745910217",
		SoundGroup = ParkourSounds,
		ShouldReplicate = true,
	},

	["jump"] = {
		Id = "135162567109750",
		SoundGroup = ParkourSounds,
		ShouldReplicate = true,
	},

	--kill effect sounds--
	["blackhole_warp"] = {
		Id = "18870782376",
		SoundGroup = SoundEffectsGroup
	},


	--this below is an example of what I could potentially use instead of what I have right now
	["InGame"] = {
		AudioList = {
			["vault"] = {
				Id = "123123123",
			},
		},
	},
}

return AudioConfig
