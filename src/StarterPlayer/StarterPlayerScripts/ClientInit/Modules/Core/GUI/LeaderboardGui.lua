--updates leaderboard gui
--should display deaths, kills, assists, points
--player frames are organized by match points

local LeaderboardGui = {}



local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui





function LeaderboardGui:Init(Core)
	self.LeaderboardEvent = Core:Get("SharedRemotes"):GetEvent("LeaderboardEvent")

	--gui--

	self.MainGui = PlayerGui.Leaderboard
	self.LeaderboardFrame = self.MainGui.Container.LeaderboardFrame
	self.PlayerFrameTemplate = self.LeaderboardFrame.PlayerFrameTemplate
	
end


function LeaderboardGui:Start()
	print('leaderboard start')


	self.LeaderboardEvent:Fire() --tells server player is ready to load onto leaderboard


	self.LeaderboardEvent:Connect(function(data)
		print("leaderboard event process client")
		local PlrFrame : Frame = self.LeaderboardFrame:FindFirstChild(data.TargetPlayer.Name)
		
		if data.Action == "Update" then
			print("updating leaderboard")
			--check if player frame already exists otherwise create a new one--
			if not PlrFrame then
				print('loading new gui')
				PlrFrame = self.PlayerFrameTemplate:Clone()
				PlrFrame.Name = data.TargetPlayer.Name
				PlrFrame.Player.Text = data.TargetPlayer.DisplayName
				PlrFrame.Assists.Text = "0"
				PlrFrame.Kills.Text = "0"
				PlrFrame.Points.Text = "0"
				PlrFrame.Visible = true
				PlrFrame.Parent = self.LeaderboardFrame
			end

			if data.MatchStats then
				print(data.MatchStats)

				for statName, value in data.MatchStats do
					PlrFrame[statName].Text = value
				end

			end
		elseif data.Action == "Remove" then
			if PlrFrame then
				print("destroying player frame")
				PlrFrame:Destroy()
			end
		end

		
	end)
end

return LeaderboardGui