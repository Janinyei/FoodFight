--CharacterManager
--Manages character spawning
--Tzu 12/06/25

local CharacterManager = {}
local Players = game:GetService("Players")

-- Constants
local LOBBY_CFRAME = CFrame.new(0, 1000, 0) -- gonna be changed later

function CharacterManager:Init(Core)
	self.Core = Core
	self.CharacterEvent = Core:Get("SharedRemotes"):GetEvent("CharacterEvent")
	self.ActivePlayers = {} -- (clicked Play)

	Players.PlayerAdded:Connect(function(player)
		self.ActivePlayers[player] = false
		
		player.CharacterAdded:Connect(function(character)
			self:OnCharacterAdded(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.ActivePlayers[player] = nil
	end)
	
	self.CharacterEvent:Connect(function(player, action)
		if action == "RequestJoin" then
			self:RequestJoin(player)
		end
	end)
end

function CharacterManager:Start()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			self:OnCharacterAdded(player, player.Character)
		end
	end
end

function CharacterManager:OnCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Died:Once(function()
			self.ActivePlayers[player] = false
		end)
	end
end

function CharacterManager:ReturnToLobby(player)
	if not self.ActivePlayers[player] then return end
	if not player.Character then return end
	
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end	
	
	hrp.CFrame = workspace.Spawn.SpawnLocation.CFrame
	hrp.Anchored = true
	self.CharacterEvent:Fire(player, "SetState", {State = "Lobby", Position = LOBBY_CFRAME.Position})
	self.ActivePlayers[player] = false
end

function CharacterManager:RequestJoin(player)
	print(player.Name .. " request join")
	if self.ActivePlayers[player] then return end
	self.ActivePlayers[player] = true
    
	local RoundManager = self.Core:Get("RoundManager")
	if RoundManager.CurrentMode == RoundManager.Modes.InGame then
		local spawnCFrame = RoundManager:GetSpawnPoint()
		self:SpawnInGame(player, spawnCFrame)
	end
end

function CharacterManager:SpawnInGame(player, spawnCFrame)
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = false
		hrp.CFrame = spawnCFrame
	end
	self.CharacterEvent:Fire(player, "SetState", {State = "Game"})
end

return CharacterManager
