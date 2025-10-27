--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
--Modules--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils

local Signal = require(Utils.Signal)
local ProfileStore = require(script.ProfileStore)

local module = {}

--Variables--
local PlayerStore = nil

function module:Init(Core)
	PlayerStore = ProfileStore.New("TestingData", self.DefaultData)
	self.Profiles = {}
	self.DataLoaded = Signal.new()
	self.DataEvent = Core:Get("SharedRemotes"):GetEvent("DataEvent")

	local function PlayerAdded(player)
		-- Start a profile session for this player's data:
		local profile = PlayerStore.Mock:StartSessionAsync(`{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})

		-- Handling new profile session or failure to start it:
		if profile ~= nil then
			profile:AddUserId(player.UserId) -- GDPR compliance
			profile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE (optional)

			profile.OnSessionEnd:Connect(function()
				self.Profiles[player] = nil
				player:Kick(`Profile session end - Please rejoin`)
			end)

			if player.Parent == Players then
				self.Profiles[player] = profile
				print(`Profile loaded for {player.DisplayName}!`)
				
				self.DataEvent:Fire(true, player, "your data has loaded")
				self.DataLoaded:Fire(player, profile.Data)
			else
				-- The player has left before the profile session started
				profile:EndSession()
			end
		else
			-- This condition should only happen when the Roblox server is shutting down
			player:Kick(`Profile load fail - Please rejoin`)
		end
	end

	-- In case Players have joined the server earlier than this script ran:
	for _, player in Players:GetPlayers() do
		task.spawn(PlayerAdded, player)
	end

	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		local profile = self.Profiles[player]
		if profile ~= nil then
			profile:EndSession()
		end
	end)
end

function module:Start()
	self.DataEvent:Connect(function(player)
		return module:GetData(player)
	end)
end

function module:GetData(player: Player)
	local profile = self.Profiles[player]

	if profile.Data ~= nil then
		return profile.Data
	else
		warn(`No profile found for {player.DisplayName}`)
	end

	return nil
end

--Default data (migrated from separate module to here)--
module.DefaultData = {
	Currency = {
		Coins = 50,
		Gems = 0,
	},
	Level = 0,
	Exp = 0, --Max exp is calculated based on exp & level. No need to save in here.
	Rank = "Novice",

	Inventory = {
		--Food is NOT stack-able
		Food = {
			Burger = {
				Name = "Burger",
				Type = "Food",
			},
		},

		--Skins ARE stack-able
		Skins = {
			Lava = {
				Name = "Lava",
				Type = "Skin",
				Amount = 1,
			},
		},

		Auras = {
			Flame = {
				Name = "Flame",
				Type = "Aura",
				Amount = 3,
			},
		},
	},

	Settings = {
		Sound = true,
		Music = true,
	},
}

return module
