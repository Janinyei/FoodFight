-- Purpose: manages map and mode voting on the server
-- janin 1/10/26

local ServerStorage = game:GetService("ServerStorage")
local VoteManager = {}

local Players = game:GetService("Players")

function VoteManager:Init(Core)
	self.Core = Core
	self.CanVote = false
	self.VoteEvent = Core:Get("SharedRemotes"):GetEvent("VoteEvent")
	self.GameManager = Core:Get("GameManager")
	self.MapManager = Core:Get("MapManager")

	self.OptionData = { Maps = {}, Modes = {} }
	self.VoteCache = { Maps = {}, Modes = {} }
end

function VoteManager:Start()
	self.VoteEvent:Connect(function(player, playerVoteData)
		if self.CanVote and playerVoteData then
			self:UpdateVotes(player, playerVoteData)
		end
	end)


	--loads vote menu for late players
	Players.PlayerAdded:Connect(function(player)
		if self.CanVote then
			self.VoteEvent:Fire(true, player, "Enable")
		end
	end)
end

function VoteManager:UpdateVotes(player, playerVoteData)
	local vType = playerVoteData.voteType
	local vIndex = tonumber(playerVoteData.voteIndex)

	if not self.OptionData[vType] or not self.OptionData[vType][vIndex] then
		return
	end

	-- 1. Remove player from previous votes in this category
	for _, playerList in pairs(self.VoteCache[vType]) do
		local existingIndex = table.find(playerList, player)
		if existingIndex then
			table.remove(playerList, existingIndex)
		end
	end

	-- 2. Add to new vote
	local optionName = self.OptionData[vType][vIndex]
	table.insert(self.VoteCache[vType][optionName], player)

	--send event to the other clients
	self.VoteEvent:Fires(true, "UpdateHeadshot", {
			Player = player,
			voteType = vType,
			OptionIndex = vIndex,
			Position = playerVoteData.Position
		})
end

function VoteManager:EnableVoting()
	self:_refreshOptionData()
	self.CanVote = true
	self.VoteEvent:Fires(true, "Enable", self.OptionData)
end

function VoteManager:DisableVoting()
	self.CanVote = false
	self.VoteEvent:Fires(true, "Disable")
end

-- Refreshes the 3 maps and 3 modes
function VoteManager:_refreshOptionData()
	self.OptionData = { Maps = {}, Modes = {} }
	self.VoteCache = { Maps = {}, Modes = {} }

	-- Setup Modes
	local availableModes = table.clone(self.GameManager.PlayableModes)
	for i = 1, 3 do
		if #availableModes == 0 then break end
		local randIndex = math.random(1, #availableModes)
		local modeName = table.remove(availableModes, randIndex)
		table.insert(self.OptionData.Modes, modeName)
		self.VoteCache.Modes[modeName] = {}
	end

	-- Setup Maps
	local allMaps = ServerStorage.Maps:GetChildren()
	for i = 1, 3 do
		if #allMaps == 0 then break end
		local randIndex = math.random(1, #allMaps)
		local map = table.remove(allMaps, randIndex)
		table.insert(self.OptionData.Maps, map.Name)
		self.VoteCache.Maps[map.Name] = {}
	end
end

-- Returns the winning Map and Mode
function VoteManager:GetWinners()
	local function calculateWinner(category)
		local winner = self.OptionData[category][1]
		local maxVotes = -1

		print(self.OptionData)
		for optionName, players in pairs(self.VoteCache[category]) do
			if #players > maxVotes then
				maxVotes = #players
				winner = optionName
			end
		end

        print(winner .. " has won with " .. maxVotes .. " votes!")
		return winner
	end

    
	return calculateWinner("Maps"), calculateWinner("Modes")
end

return VoteManager
