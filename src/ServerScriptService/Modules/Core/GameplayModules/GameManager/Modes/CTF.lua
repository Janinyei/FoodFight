local CTF = {}

-- Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Flag Class
local Flag = {}
Flag.__index = Flag

function Flag.new(teamName, baseCFrame, model)
	local self = setmetatable({}, Flag)
	self.TeamName = teamName
	self.BaseCFrame = baseCFrame
	self.Model = model
	self.Carrier = nil
	self.IsHome = true
	self.DroppedTimer = 0
	
	if self.Model then
		self.Model.Name = teamName .. "_Flag"
		self.Model.Color = (teamName == "red" and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 0, 255))
		self.Model.Anchored = true
		self.Model.CanCollide = false
		self.Model.CFrame = baseCFrame
		
		self.Model.Touched:Connect(function(hit)
			self:OnTouch(hit)
		end)
	end
	
	return self
end

function Flag:OnTouch(hit)
	local char = hit.Parent
	local player = Players:GetPlayerFromCharacter(char)
	if not player then return end
	
	local playerTeam = CTF.TeamManager.Teams[player.Name] and "fighter" -- Hacky fallback
	for name, teamData in pairs(CTF.TeamManager.Teams) do
		if table.find(teamData.Players, player) then
			playerTeam = name
			break
		end
	end
	
	if not playerTeam then return end
	
	if playerTeam ~= self.TeamName and not self.Carrier and not self.IsHome then
		self:Pickup(player)
	elseif playerTeam ~= self.TeamName and not self.Carrier and self.IsHome then
		self:Pickup(player)
	elseif playerTeam == self.TeamName and not self.Carrier and not self.IsHome then
		self:Return()
		CTF.MatchStatsManager:IncrementTeam(playerTeam, "Points", 20) -- Small bonus for return
	end
end

function Flag:Pickup(player)
	self.Carrier = player
	self.IsHome = false
	self.Model.Transparency = 1
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		self.Model.CFrame = char.HumanoidRootPart.CFrame
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = self.Model
		weld.Part1 = char.HumanoidRootPart
		weld.Parent = self.Model
		self.Weld = weld
		self.Model.Anchored = false
		self.Model.Transparency = 0
	end
	print(player.Name .. " picked up " .. self.TeamName .. " flag!")
end

function Flag:Drop(position)
	self.Carrier = nil
	self.IsHome = false
	if self.Weld then self.Weld:Destroy() end
	self.Model.Anchored = true
	self.Model.CFrame = CFrame.new(position)
	print(self.TeamName .. " flag dropped!") 
end

function Flag:Return()
	self.Carrier = nil
	self.IsHome = true
	if self.Weld then self.Weld:Destroy() end
	self.Model.Anchored = true
	self.Model.CFrame = self.BaseCFrame
	print(self.TeamName .. " flag returned!")
end

-- CTF Module

function CTF:InitMode(Core)
	self.Name = "CTF"
	self.DisplayName = "Capture the Flag"
	self.Core = Core
	
	self.TeamManager = Core:Get("TeamManager")
	self.FoodCombatManager = Core:Get("FoodCombatManager")
	self.MatchStatsManager = Core:Get("MatchStatsManager")
	
	self.Flags = {}
	self._connections = {}
end

function CTF:StartMode()
	print("Starting CTF Mode")
	
	-- Setup Teams
	self.TeamManager:CleanupTeams()
	self.TeamManager:CreateTeamsFromMode("CTF")
	self.TeamManager:AutoAssignBalancedTeams()
	self.MatchStatsManager:ResetTeamScores()
	
	local map = workspace:FindFirstChild("Map")
	local redBasePos = CFrame.new(0, 5, 100)
	local blueBasePos = CFrame.new(0, 5, -100)
	
	if map then
		local redBase = map:FindFirstChild("RedFlagBase", true)
		local blueBase = map:FindFirstChild("BlueFlagBase", true)
		if redBase then redBasePos = redBase.CFrame end
		if blueBase then blueBasePos = blueBase.CFrame end
	end
	
	self:SpawnFlag("red", redBasePos)
	self:SpawnFlag("blue", blueBasePos)
	
	table.insert(self._connections, self.FoodCombatManager.Eliminated:Connect(function(data)
		self:OnElimination(data)
	end))
	
	table.insert(self._connections, RunService.Heartbeat:Connect(function()
		self:OnTick()
	end))
end

function CTF:SpawnFlag(team, cframe)
	local part = Instance.new("Part")
	part.Size = Vector3.new(2, 8, 2)
	part.Anchored = true
	part.CanCollide = false
	part.Position = cframe.Position
	part.Parent = workspace
	
	local flag = Flag.new(team, cframe, part)
	table.insert(self.Flags, flag)
end

function CTF:OnElimination(data)
	local victim = data.Victim
	local killer = data.Killer
	
	-- Check if victim had flag
	for _, flag in pairs(self.Flags) do
		if flag.Carrier == victim then
			local dropPos = victim.Character and victim.Character.HumanoidRootPart.Position or flag.Model.Position
			flag:Return() 

			if killer and killer:IsA("Player") then
				self.MatchStatsManager:Increment(killer, "Points", 100)
			end
			print("Flag returned due to kill!")
		end
	end
end

function CTF:OnTick()
	for _, flag in pairs(self.Flags) do
		if flag.Carrier then
			local carrier = flag.Carrier
			local carrierTeam = nil
			for name, teamData in pairs(self.TeamManager.Teams) do
				if table.find(teamData.Players, carrier) then
					carrierTeam = name
					break
				end
			end
			
			if carrierTeam and carrierTeam ~= flag.TeamName then
				local homeFlag = nil
				for _, f in pairs(self.Flags) do
					if f.TeamName == carrierTeam then
						homeFlag = f
						break
					end
				end
				
				if homeFlag and homeFlag.IsHome then
					local dist = (flag.Model.Position - homeFlag.BaseCFrame.Position).Magnitude
					if dist < 15 then
						-- CAPTURE!
						self:Capture(flag, carrierTeam, carrier)
					end
				end
			end
		end
	end
end

function CTF:Capture(flag, scoringTeam, player)
	print(scoringTeam .. " Captured the flag!")
	self.MatchStatsManager:IncrementTeam(scoringTeam, "Points", 500)
	self.MatchStatsManager:Increment(player, "Points", 200)
	flag:Return()
end

function CTF:OnComplete()
	-- Cleanup
	for _, conn in self._connections do
		conn:Disconnect()
	end
	self._connections = {}
	
	for _, flag in pairs(self.Flags) do
		if flag.Model then flag.Model:Destroy() end
	end
	self.Flags = {}
	
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
		print("CTF Winner Team: " .. winnerTeam)

	end
end

return CTF