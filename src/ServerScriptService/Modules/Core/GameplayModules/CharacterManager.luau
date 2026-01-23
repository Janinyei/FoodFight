--Purpose: Manages status effects to the character, and pretty much anything else that the server may need to handle the character on the server with
--note: very useful when a lot is going on in the game

local CharacterManager = {}
local Players = game.Players

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules

local UtilFunctions = require(Modules.Utils.Functions)
local Signal = require(Modules.Utils.Signal)

function CharacterManager:Init(Core)
	self.StatusEffectManager = Core:Get("StatusEffectManager")

	self.FoodCombatManager = Core:Get("FoodCombatManager")

	self.GameManager = Core:Get("GameManager")
	self.TeamManager = Core:Get("TeamManager")
	self.SharedRemotes = Core:Get("SharedRemotes")
	self.CombatEvent = self.SharedRemotes:GetEvent("CombatEvent")
	self.RespawnTime = 5 --typical respawn time
	self.CharacterEvent = self.SharedRemotes:GetEvent("CharacterEvent")
end

function CharacterManager:Start()
	--Spawn Management--

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			char.Archivable = true --allows character model cloning
			--setup ragdoll constraints--
			local hum = char:WaitForChild("Humanoid")
			hum.BreakJointsOnDeath = false
			self:_setupRagdollConstraints(char)

			hum.Died:Connect(function()
				self.StatusEffectManager:RemoveAllEffects(player)

				self:OnDeath(player, char)
			end)
		end)

		self:SpawnCharacter(player) --make sure this line is placed after the characteradded event
	end)

	self.CharacterEvent:Connect(function(player, action)
		print(action)
		if action == "Spawn" then
			self:SpawnCharacter(player)
		end
	end)

	--Status Effect Management--
	self.StatusEffectManager.StatusEffectApplied:Connect(function(plr, effectName)
		if effectName == "Ragdoll" then
			--self:EnableRagdoll(plr.Character)
			--	UtilFunctions.ToggleRagdoll(plr.Character, true)
		end
	end)

	self.StatusEffectManager.StatusEffectRemoved:Connect(function(plr, effectName)
		if effectName == "Ragdoll" then
			self:DisableRagdoll(plr.Character)
		end
	end)
end

function CharacterManager:SpawnCharacter(plr: Player)
	plr:LoadCharacterAsync()

	warn("character loading on server")

	if self.GameManager.GameData.InGame == true then
		table.insert(self.GameManager.ActivePlayers, plr)

		local CurrentMapModel = workspace.Map[self.GameManager.GameData.CurrentMap]
		local Gameplay = CurrentMapModel.Gameplay
		local SpawnZones = Gameplay.SpawnZones:GetChildren()

		local targetZone = self:_getBestSpawnZone(plr, SpawnZones)

		if targetZone then
			local spawnPos = self:_getSpawnPos(targetZone, targetZone)
			plr.Character.HumanoidRootPart.CFrame = spawnPos
		else
			warn("no safe spawn zone found")
		end
	end
end

function CharacterManager:OnDeath(player, char)
	--self:EnableRagdoll(char)

	char.PrimaryPart:SetNetworkOwner(player) --needed to control

	local corpse = char:Clone()
	corpse.Parent = workspace.SpatialQueryBlacklist
	corpse.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame
	corpse.Humanoid.Health = math.huge
	corpse.Humanoid.MaxHealth = math.huge
	corpse.PrimaryPart:SetNetworkOwner(player)
	player.Character:Destroy()
	player.Character = nil

	--	hum.RootPart:ApplyImpulse(hum.RootPart:GetMass() * Vector3.yAxis * 500)
	--	hum.RootPart:ApplyAngularImpulse(hum.RootPart:GetMass() * Vector3.one * math.random(100, 500))

	--[[]]
	local activePlrIndex = table.find(self.GameManager.ActivePlayers, player)
	if activePlrIndex then
		table.remove(self.GameManager.ActivePlayers, activePlrIndex)
	end

	--handles killcam, kill effects, and more i think
	self.FoodCombatManager:ProcessElimination(player, corpse)

	--test respawning, delete later:
	task.delay(self.RespawnTime, function()
		self:SpawnCharacter(player)
	end)
end

--priv

function CharacterManager:_setupRagdollConstraints(char)
	for _, v in pairs(char:GetDescendants()) do --ragdoll
		if v:IsA("Motor6D") then
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.CFrame = v.C0
			a1.CFrame = v.C1
			a0.Parent = v.Part0
			a1.Parent = v.Part1
			local b = Instance.new("BallSocketConstraint")
			b.Attachment0 = a0
			b.Attachment1 = a1
			b.Parent = v.Part0
			b.Enabled = false
			v.Enabled = true
		end
	end
end

--private

function CharacterManager:_getBestSpawnZone(player, zones: { Part })
	local playerTeam = self.TeamManager:GetTeam(player)
	local SpawnCheckDistance = 45
	local bestZone = zones[1]
	local minEnemyCount = 999

	if playerTeam then
		for _, zone in zones do
			local enemiesInRange = 0

			--check all players in the game

			for _, otherPlr in self.GameManager.ActivePlayers do
				if otherPlr and otherPlr.Character == nil then
					continue
				end

				local otherTeam = self.TeamManager:GetTeam(otherPlr)
				if otherTeam ~= playerTeam then
					local dist = (otherPlr.Character.PrimaryPart.Position - zone.Position).Magnitude
					if dist < SpawnCheckDistance then
						enemiesInRange += 1
					end
				end
			end

			if enemiesInRange < minEnemyCount then
				minEnemyCount = enemiesInRange
				bestZone = zone
			end
		end
	end

	return bestZone
end

function CharacterManager:_getSpawnPos(character, zone: Part)
	if not zone then
		warn("zone is nil")
		return
	end
	local zoneSize = zone.Size

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { character, workspace.SpatialQueryBlacklist }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	-- Random point in the part's X/Z
	local rx = (math.random() - 0.5) * zoneSize.X
	local rz = (math.random() - 0.5) * zoneSize.Z
	local startPos = (zone.CFrame * CFrame.new(rx, zoneSize.Y / 2, rz)).Position
	
	print(startPos)

	-- Raycast down to find the ground
	local rayResult = workspace:Raycast(startPos, Vector3.yAxis * -999, rayParams)

	if rayResult and rayResult.Instance then
		local targetPos = rayResult.Position + Vector3.new(0, 3, 0) -- Offset for HRP height

		return CFrame.new(targetPos)
	else  
		return CFrame.new(startPos) --if all else fails lol
	end
end

return CharacterManager
