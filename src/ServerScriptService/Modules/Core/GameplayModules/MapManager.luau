-- Purpose: Handles loading and unloading of maps
-- janin 1/10/26

local ServerStorage = game:GetService("ServerStorage")


local MapManager = {}

--local MapIndex = require(ReplicatedStorage.Modules.Info.MapIndex)
local MapStorage = ServerStorage.Maps

function MapManager:Init(Core)
	self.Core = Core
	self.CurrentMap = nil
	self.CurrentMapModel = nil
end

function MapManager:Start()
	--idk
end

-- Loads a specific map by name
function MapManager:LoadMap(mapName: string)
	-- 1. Cleanup the old map first
	if self.CurrentMap then
		self:CleanupCurrentMap()
	end

	print("Loading " .. mapName)

	local mapTemplate = MapStorage:FindFirstChild(mapName)
	if not mapTemplate then
		warn("MapManager: Map " .. mapName .. " not found in ServerStorage.Maps")
		return
	end

	local mapClone = mapTemplate:Clone()
	mapClone.Parent = workspace.Map

	if  mapClone:IsA("Model") then
		mapClone:PivotTo(CFrame.new(0, 0, 0))
	else
		warn("map must be a model to position correctly")
	end

	self.CurrentMap = mapName
	self.CurrentMapModel = mapClone
	return mapClone
end

-- Selects a random map from the folder
function MapManager:LoadRandomMap()
	local maps = MapStorage:GetChildren()
	if #maps == 0 then
		warn("MapStorage is empty!")
		return
	end

	local randomMap = maps[math.random(1, #maps)]
	return self:LoadMap(randomMap.Name)
end

-- Removes the current map and cleans up associated data
function MapManager:CleanupCurrentMap()
	if not self.CurrentMapModel then
		return
	end

	print("Cleaning up map: " .. self.CurrentMap)

	self.CurrentMapModel:Destroy()
	self.CurrentMapModel = nil
	self.CurrentMap = nil
end

-- Helper to get specific spawn points from the current map
function MapManager:GetSpawns()
	if not self.CurrentMapModel then
		return {}
	end
	local spawnsFolder = self.CurrentMapModel:FindFirstChild("Spawns")
	return spawnsFolder and spawnsFolder:GetChildren() or {}
end

return MapManager
