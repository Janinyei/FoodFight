--GameStatusManager
--Manages character spawning
--Tzu 12/06/25

local GameStatusManager = {}
local Players = game:GetService("Players")

-- Constants
local LOBBY_CFRAME = CFrame.new(0, 1000, 0) -- gonna be changed later

function GameStatusManager:Init(Core)
	self.Core = Core
	self.GameStatusEvent = Core:Get("SharedRemotes"):GetEvent("GameStatusEvent")
	self.GameManager = Core:Get("GameManager")
	self.ActivePlayers = {} -- (clicked Play)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			self:OnCharacterAdded(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		table.remove(self.ActivePlayers, table.find(self.ActivePlayers, player))
	end)
	
	self.GameStatusEvent:Connect(function(player, action)
		if action == "RequestJoin" then
			self:RequestJoin(player)
		end
	end)
end

function GameStatusManager:Start()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			self:OnCharacterAdded(player, player.Character)
		end
	end
end

function GameStatusManager:OnCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Died:Once(function()
		table.remove(self.ActivePlayers, table.find(self.ActivePlayers, player))
		end)
	end
end

function GameStatusManager:ReturnToLobby(player)
	if not player.Character then return end
	
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end	

	local spawnPart = nil
	if workspace:FindFirstChild("Spawn") and workspace.Spawn:FindFirstChild("SpawnLocation") then
		spawnPart = workspace.Spawn:FindFirstChild("SpawnLocation")
	elseif workspace:FindFirstChild("SpawnLocation") then
		spawnPart = workspace:FindFirstChild("SpawnLocation")
	end

	if spawnPart and spawnPart:IsA("BasePart") then
		hrp.CFrame = spawnPart.CFrame
	else
		hrp.CFrame = LOBBY_CFRAME
	end
	hrp.Anchored = true
	self.GameStatusEvent:Fire(true, player, "SetState", {State = "Lobby", Position = LOBBY_CFRAME.Position})
table.remove(self.ActivePlayers, table.find(self.ActivePlayers, player))
end

function GameStatusManager:RequestJoin(player)
	local GameManager = self.GameManager
	print(GameManager.CurrentMode.Name)

	if GameManager.CurrentMode.Name == "Intermission" then return end 
	if table.find(self.ActivePlayers, player) ~= nil then return end --no point if they're already active

	table.insert(self.ActivePlayers, player)

	print("player is now active")
	local spawnCFrame = GameManager:GetSpawnPoint()
	self:SpawnInGame(player, spawnCFrame)
end

function GameStatusManager:SpawnInGame(player, spawnCFrame)
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = false
		hrp.CFrame = spawnCFrame
	end
	self.GameStatusEvent:Fire(true, player, "SetState", {State = "Game"})
end

return GameStatusManager
