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
	ProfileStore.OnError:Connect(function(message, store_name, profile_key)
		warn(`[DataManager]: ProfileStore error (STORE:{store_name}; KEY:{profile_key}) - {message}`)
	end)

	self.Profiles = {}
	self.DataLoaded = Signal.new()
	self.DataEvent = Core:Get("SharedRemotes"):GetEvent("DataEvent")

	local function PlayerAdded(player)
		local profile = PlayerStore.Mock:StartSessionAsync(`{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,

		})

		if profile ~= nil then
			profile:AddUserId(player.UserId)
			profile:Reconcile()

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
				profile:EndSession()
			end
		else
			warn(`Profile load failed for {player.DisplayName}, retrying...`)
			task.wait(2)
			profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
				Cancel = function()
					return player.Parent ~= Players
				end,
			})

			if profile ~= nil then
				profile:AddUserId(player.UserId)
				profile:Reconcile()

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
					profile:EndSession()
				end
			else
				player:Kick(`Profile load fail - Please rejoin`)
			end
		end
	end

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

	Progression = {
		Level = 0,
		Exp = 0, --Max exp is calculated based on exp & level. No need to save in here.
		Rank = "Novice",
	},


	Inventory = {
		--Food is NOT stack-able

		Equipped = {
			Food = "Banana",
			Trails = "Basic",
			Auras = "idk", --can't set to nil cuz ProfileStore deletes nil keys
			KillEffects = "Blackhole",
		},

		Food = {
			Burger = {
				Name = "Burger",
				Type = "Food",
			},
		},

		Trails = {
			Basic = {
				Name = "Basic",
				Type = "Trails",
				Amount = 1,
			},

			Fire = {
				Name = "Fire",
				Type = "Trails",
				Amount = 1,
			},
		},

		Auras = {
			Flame = {
				Name = "Flame",
				Type = "Auras",
				Amount = 3,
			},
		},

		KillEffects = {
			Blackhole = {
				Name = "Blackhole",
				Type = "KillEffects",
				Amount = 1
			}
		}
	},

	Settings = {
		Sound = true,
		Music = true,
	},
}

return module
