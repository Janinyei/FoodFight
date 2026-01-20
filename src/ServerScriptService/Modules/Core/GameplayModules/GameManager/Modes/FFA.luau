local FFA = {}

-- Services
local Players = game:GetService("Players")

function FFA:InitMode(Core)
	self.Core = Core
	self.Name = "FFA"
	self.DisplayName = "Free For All"
	self.DescriptionText = "Fight any Player you can find!"
	
	self.TeamManager = Core:Get("TeamManager")
	self.FoodCombatManager = Core:Get("FoodCombatManager")
	self.MatchStatsManager = Core:Get("MatchStatsManager")
	self.CurrencyManager = Core:Get("CurrencyManager")
	
	self._connections = {}
end

function FFA:StartMode()
	print("Starting FFA Mode")
	
	-- Setup Teams
	self.TeamManager:CleanupTeams()
	self.TeamManager:CreateTeamsFromMode("FFA")
	self.TeamManager:AutoAssignBalancedTeams() -- Will assign all to 'fighter'
	
	table.insert(self._connections, self.FoodCombatManager.Eliminated:Connect(function(data)
		local killer = data.Killer
		if killer and killer:IsA("Player") then
			self.CurrencyManager:AddCurrency(killer, "Coins", 10)
		end
	end))
end

function FFA:OnComplete()
	-- Cleanup connections
	for _, conn in self._connections do
		conn:Disconnect()
	end
	self._connections = {}
	
	-- Determine Winner
	local highestPoints = -1
	local winner = nil
	
	for player, stats in pairs(self.MatchStatsManager.PlayerData) do
		if stats.Points > highestPoints then
			highestPoints = stats.Points
			winner = player
		end
	end
	
	if winner then
		print("FFA Winner: " .. winner.Name .. " with " .. highestPoints .. " points!")
		--self.CurrencyManager:AddCurrency(winner, "Coins", 50)
	else
		print("No winner found.")
	end
end

return FFA