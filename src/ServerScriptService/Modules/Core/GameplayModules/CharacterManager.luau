--Purpose: Manages status effects to the character, and pretty much anything else that the server may need to handle the character on the server with
--note: very useful when a lot is going on in the game

local CharacterManager = {}
local Players = game.Players

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules

local UtilFunctions = require(Modules.Utils.Functions)

function CharacterManager:Init(Core)
	self.StatusEffectManager = Core:Get("StatusEffectManager")
	Players.RespawnTime = 1000000

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			--setup ragdoll constraints--
			local hum = char:WaitForChild("Humanoid")
			hum.BreakJointsOnDeath = false
			self:_setupRagdollConstraints(char)
			
			local SharedRemotes = Core:Get("SharedRemotes")
			local CombatEvent = SharedRemotes:GetEvent("CombatEvent")

			hum.Died:Connect(function()
				self:EnableRagdoll(char)

				hum.RootPart:ApplyImpulse(hum.RootPart:GetMass() * Vector3.yAxis * 500)
				hum.RootPart:ApplyAngularImpulse(hum.RootPart:GetMass() * Vector3.one * math.random(100, 500))

				local CreatorTag = hum:FindFirstChild("creator")
				local Killer = nil
				if CreatorTag and CreatorTag.Value then
					Killer = CreatorTag.Value
				end

				CombatEvent:Fire(true, player, "YouDied", {
					Killer = Killer
				})
			end)
		end)
	end)
end

function CharacterManager:Start()
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
