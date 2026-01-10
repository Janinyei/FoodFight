--purpose: relays signals and events from scripts such as match stats manager and team manager to update information about players on the leaderboard to the client
--note:
--note: use a team config for colors

local LeaderboardManager = {}

-- Services
local Players = game:GetService("Players")

function LeaderboardManager:Init(Core)
	--link events which involve leader board updates

	self.LeaderboardEvent = Core:Get("SharedRemotes"):GetEvent("LeaderboardEvent")
	self.DataManager = Core:Get("DataManager")
end

function LeaderboardManager:Start()
	--player add/remove functionality

	--runs when player joins and data is loaded
	self.DataManager.DataLoaded:Connect(function(player, data)
		self.LeaderboardEvent:Fires(true, {

            Action = "Update",

			TargetPlayer = player,
			Level = data.Progression.Level,

		})
	end)

	Players.PlayerRemoving:Connect(function(player, reason)
		self.LeaderboardEvent:Fires(true,  {

            Action = "Remove",


			TargetPlayer = player,

		})
	end)
end

return LeaderboardManager
