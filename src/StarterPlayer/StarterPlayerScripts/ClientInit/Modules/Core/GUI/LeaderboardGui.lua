--updates leaderboard gui
--should display deaths, kills, assists, points
--player frames are organized by match points

local LeaderboardGui = {}




function LeaderboardGui:Init(Core)
	self.LeaderboardEvent = Core:Get("SharedRemotes"):GetEvent("LeaderboardEvent")

	--gui--
end


function LeaderboardGui:Start()
	self.LeaderboardEvent:Connect(function(data)
		
		if data.Action == "Update" then
			--check if player frame already exists otherwise create a new one--
			
		end

		
	end)
end

return LeaderboardGui