local GameConstants = require(game.ReplicatedStorage.Modules.Info.GameConstants)
local Players = game:GetService("Players")

local KOH = {}

-- Constants
local CAPTURE_RATE = 0.1 -- Progress per check
local SCORE_RATE = 10 -- Points per tick for owner/presence
local SCORE_LIMIT = 1000

function KOH:InitMode(Core)
	self.Core = Core
	self.Name = "KOH"
	self.DisplayName = "King of the Hill"
	self.DescriptionText = "Control the hill to reach " .. SCORE_LIMIT .. " points!"
	
	self.TeamManager = Core:Get("TeamManager")
	self.MatchStatsManager = Core:Get("MatchStatsManager")
	self.GameManager = Core:Get("GameManager")
	self.KOHUpdate = Core:Get("SharedRemotes"):GetEvent("KOHUpdate")
	self.Duration = GameConstants.ROUND_DURATION

	self.Zones = {}
	self.ZoneStates = {}
end

function KOH:StartMode()
	print("Starting KOH Mode")
	
	self.TeamManager:CleanupTeams()
	self.TeamManager:CreateTeamsFromMode("KOH")
	self.TeamManager:AutoAssignBalancedTeams()
	self.MatchStatsManager:ResetTeamScores()

	self.Zones = {}
	self.ZoneStates = {}

	local map = workspace.Map:FindFirstChild(self.GameManager.GameData.CurrentMap)
	if map then
		local zonesFolder = map:FindFirstChild("Gameplay"):FindFirstChild("HillZones")
		if zonesFolder then
			for _, zone in ipairs(zonesFolder:GetChildren()) do
				if zone:IsA("BasePart") then
					table.insert(self.Zones, zone)
					zone.Color = Color3.fromRGB(150, 150, 150)
					
					self.ZoneStates[zone] = {
						Id = zone.Name,
						Owner = nil,
						CapturingTeam = nil,
						Progress = 0,
						IsContested = false
					}
				end
			end
		end
	end

	self:Replicate()
end

function KOH:OnTick(TimeRemaining)
	for _, zone in ipairs(self.Zones) do
		local state = self.ZoneStates[zone]
		if not state then continue end

		local teamCounts = self:GetPlayersInZone(zone)
		local presentTeams = {}
		
		for team, count in pairs(teamCounts) do
			if count > 0 then 
				-- Any team inside the zone gets points
				self.MatchStatsManager:IncrementTeam(team, "Points", SCORE_RATE)
				table.insert(presentTeams, team) 
			end
		end

		-- Passive Points for Ownership
		if state.Owner then
			self.MatchStatsManager:IncrementTeam(state.Owner, "Points", SCORE_RATE)
			
			-- Score Cap Check
			local score = self.MatchStatsManager.TeamScores[state.Owner].Points or 0
			if score >= SCORE_LIMIT then
				self.GameManager:SetMode("Intermission")
				return
			end
		end

		-- Capture Progress (Only if UNCONTESTED)
		local dominantTeam = #presentTeams == 1 and presentTeams[1] or nil
		state.IsContested = #presentTeams > 1

		if dominantTeam then
			if state.Owner and state.Owner ~= dominantTeam then
				-- Decapturing Enemy Hill
				state.Progress -= CAPTURE_RATE
				if state.Progress <= 0 then
					state.Progress = 0
					state.Owner = nil
					state.CapturingTeam = dominantTeam
				end
			elseif not state.Owner then
				-- Capturing Neutral Hill
				if state.CapturingTeam ~= dominantTeam then
					state.CapturingTeam = dominantTeam
					state.Progress = 0
				end
				
				state.Progress += CAPTURE_RATE
				if state.Progress >= 1 then
					state.Progress = 1
					state.Owner = dominantTeam
				end
			else
				-- Maintain ownership progress
				state.Progress = 1
			end
		end

		self:UpdateVisuals(zone, state)
	end
	
	self:Replicate()
end

function KOH:GetPlayersInZone(zone)
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = {workspace.Map, workspace.SpatialQueryBlacklist}
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	local parts = workspace:GetPartBoundsInBox(zone.CFrame, zone.Size, params)
	local teamCounts = {}
	local playersFound = {}

	for _, part in ipairs(parts) do
		local char = part.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if player and not playersFound[player] then
			playersFound[player] = true
			local team = self.TeamManager:GetTeam(player)
			if team then
				teamCounts[team] = (teamCounts[team] or 0) + 1
			end
		end
	end
	return teamCounts
end

function KOH:UpdateVisuals(zone, state)
	local neutralColor = Color3.fromRGB(150, 150, 150)
	local targetColor = neutralColor
	
	if state.Owner then
		local config = self.TeamManager.Teams[state.Owner].Config
		targetColor = config.Color
	elseif state.CapturingTeam then
		local config = self.TeamManager.Teams[state.CapturingTeam].Config
		targetColor = neutralColor:Lerp(config.Color, state.Progress)
	end
	zone.Color = targetColor
end

function KOH:Replicate()
	local scores = {}
	for team, data in pairs(self.MatchStatsManager.TeamScores) do
		scores[team] = data.Points or 0
	end
	
	local hillData = {}
	for _, state in pairs(self.ZoneStates) do
		table.insert(hillData, state)
	end

	self.KOHUpdate:Fires(true, {
		Hills = hillData,
		Scores = scores
	})
end

function KOH:OnComplete()
	local winner = nil
	local high = -1
	for team, score in pairs(self.MatchStatsManager.TeamScores) do
		local points = score.Points or 0
		if points > high then
			high = points
			winner = team
		end
	end
	
	if winner then
		print("Winner: " .. winner)
	end
end

return KOH
