--Purpose: levels and rank management.
--janin 10/28/25

local ProgressionManager = {}

--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Variables--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils
local Ranks = require(Modules.Info.RankIndex)

--Constants--
local LEVEL_CAP = 100

function ProgressionManager:Init(Core)
	self.DataManager = Core:Get("DataManager")
	self.ProgressionEvent = Core:Get("SharedRemotes"):GetEvent("ProgressionEvent")
end

function ProgressionManager:Start()
	--test--
	self.DataManager.DataLoaded:Connect(function(Player, Data)
		ProgressionManager:IncreaseExp(Player, Data, 50000)
	end)
end

--functions

function ProgressionManager:IncreaseExp(Player: Player, Data, Amount: number)
	local Data = Data
	local ProgressionData = Data.Progression

	ProgressionData.Exp += Amount

	local Exp = ProgressionData.Exp
	local Level = ProgressionData.Level

	local MaxExp = self:CalculateMaxExp(Level)
	--Level up
	if Exp >= MaxExp then
		repeat
			--repetitive logic to make sure player levels/ranks up correctly

			--Level up logic
			ProgressionData.Level = math.clamp(ProgressionData.Level + 1, 0, LEVEL_CAP)
			ProgressionData.Exp -= MaxExp
			MaxExp = self:CalculateMaxExp(ProgressionData.Level)

			--determines whether players increase their rank or not
			local RankUp = self:CheckRank(ProgressionData.Level, ProgressionData.Rank)
			if RankUp ~= nil then
				ProgressionData.Rank = RankUp
			end

			self.ProgressionEvent:Fire(true, Player, ProgressionData, MaxExp) --sends to client cache. sent MaxExp since it's not being saved

		until ProgressionData.Exp < MaxExp --ends when exp is finally less than max
	else
		self.ProgressionEvent:Fire(true, Player, ProgressionData) --if the player doesn't need to level up then immediately replicate
	end
end

--calculates maximum experience required to level up based on current level
function ProgressionManager:CalculateMaxExp(Level: number): number
	return math.ceil((Level / 2) * math.log10((Level + 1) ^ 2) * 100 + 100) --some formula I came up with
end

--Finds highest rank that player qualifies for based on level and returns its string value
function ProgressionManager:CheckRank(Level: number, CurrentRank: string): string | boolean
	local HighestQualifiedRank = nil
	for RankName, RequiredLevel in Ranks do
		if Level >= RequiredLevel then
			if not HighestQualifiedRank then
				HighestQualifiedRank = RankName
			else
				--compare which rank is higher
				if Ranks[RankName] > Ranks[HighestQualifiedRank] then
					HighestQualifiedRank = RankName
				end
			end
		end
	end

	if HighestQualifiedRank ~= CurrentRank then
		return HighestQualifiedRank
	end

	return nil
end

return ProgressionManager
