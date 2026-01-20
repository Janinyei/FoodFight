local KOH = {}

-- Services
local Values = game:GetService("CollectionService")

function KOH:InitMode(Core)
	self.Core = Core
	self.Name = "KOH"
	self.DisplayName = "King of the Hill"
	self.DescriptionText = "Stay in the hill as long as possible!"
	
	self.TeamManager = Core:Get("TeamManager")
	self.MatchStatsManager = Core:Get("MatchStatsManager")
	self.FoodCombatManager = Core:Get("FoodCombatManager")
end

function KOH:StartMode()
	print("Starting KOH Mode")
	
	self.TeamManager:CleanupTeams()
	self.TeamManager:CreateTeamsFromMode("KOH")
	self.TeamManager:AutoAssignBalancedTeams()
	self.MatchStatsManager:ResetTeamScores()
	
	self.Zones = {}
	local map = workspace:FindFirstChild("Map")
	if map then
		local zonesFolder = map:FindFirstChild("GamePlay"):FindFirstChild("HillZones")
		if zonesFolder then
			for _, zone in pairs(zonesFolder:GetChildren()) do
				if zone:IsA("BasePart") then
					table.insert(self.Zones, zone)
				end
			end
		end
	end
end

function KOH:OnTick(TimeRemaining)
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = {self.Zones} 
	params.FilterType = Enum.RaycastFilterType.Include
	
	for _, zone in pairs(self.Zones) do
		local parts = workspace:GetPartBoundsInBox(zone.CFrame, zone.Size, params)
		local foundPlayers = {}
		local teamCounts = {}
		
		for _, part in pairs(parts) do
			local model = part:FindFirstAncestorOfClass("Model")
			if model then
				local player = game.Players:GetPlayerFromCharacter(model)
				if player and not foundPlayers[player] then
					foundPlayers[player] = true
					
					local pTeam = nil
					for name, teamData in pairs(self.TeamManager.Teams) do
						if table.find(teamData.Players, player) then
							pTeam = name
							break
						end
					end
					
					if pTeam then
						teamCounts[pTeam] = (teamCounts[pTeam] or 0) + 1
					end
				end
			end
		end
		
		for teamName, count in pairs(teamCounts) do
			if count > 0 then
				self.MatchStatsManager:IncrementTeam(teamName, "Points", 3 * count)
			end
		end
		
		local maxC = 0
		local domTeam = nil
		for t, c in pairs(teamCounts) do
			if c > maxC then
				maxC = c
				domTeam = t
			elseif c == maxC then
				domTeam = nil -- Tie
			end
		end
		
		if domTeam then
			local teamData = self.TeamManager.Teams[domTeam].Config
			if teamData then
				zone.Color = teamData.Color
			end
		else
			zone.Color = Color3.fromRGB(150, 150, 150)
		end
	end
end

function KOH:OnComplete()
	-- Determine Winner
	local highestScore = -1
	local winnerTeam = nil
	for team, scores in pairs(self.MatchStatsManager.TeamScores) do
		local ptrs = scores.Points or 0
		if ptrs > highestScore then
			highestScore = ptrs
			winnerTeam = team
		end
	end
	
	if winnerTeam then
		print("KOH Winner Team: " .. winnerTeam)
		-- Reward all players in team
	end
end

return KOH