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
	self.SharedRemotes = Core:Get("SharedRemotes")
	self.CombatEvent = self.SharedRemotes:GetEvent("CombatEvent")
	self.RespawnTime = 5 --typical respawn time
	self.CharacterEvent = self.SharedRemotes:GetEvent("CharacterEvent")
end

function CharacterManager:SpawnCharacter(plr: Player)
	plr:LoadCharacterAsync()

	warn("character loading on server")

	if self.GameManager.InGame == true then
		table.insert(self.GameManager.ActivePlayers, plr)
	end
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
			self:EnableRagdoll(plr.Character)
		end
	end)

	self.StatusEffectManager.StatusEffectRemoved:Connect(function(plr, effectName)
		if effectName == "Ragdoll" then
			self:DisableRagdoll(plr.Character)
		end
	end)
end

function CharacterManager:OnDeath(player, char)
	self:EnableRagdoll(char)

	char.PrimaryPart:SetNetworkOwner(player) --needed to control

	local corpse = char:Clone()
	corpse.Parent = workspace.VisualEffectsCache
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

function CharacterManager:EnableRagdoll(char)
	print("now ragdolling")
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("Motor6D") then
			v.Enabled = false
		elseif v:IsA("BallSocketConstraint") then
			v.Enabled = true
		end
	end
end

function CharacterManager:DisableRagdoll(char)
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("Motor6D") then
			v.Enabled = true
		elseif v:IsA("BallSocketConstraint") then
			v.Enabled = false
		end
	end
end

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

function CharacterManager:ApplyStatusEffect() end

function CharacterManager:CheckStatusEffect(player, StatusName: string) end

function CharacterManager:RemoveStatusEffect(player, StatusName: string, RemoveAll: boolean?) end
return CharacterManager
