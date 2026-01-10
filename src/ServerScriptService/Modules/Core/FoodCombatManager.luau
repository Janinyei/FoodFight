--Purpose: Manages network function traffic and executing server actions for food combat
--janin 12/10/25

local FoodCombatManager = {}

--Services--
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

function FoodCombatManager:IsHeadshot(targetCharacter: Model, hitPosition: Vector3?, hitInstance: Instance?)
	local head = targetCharacter:FindFirstChild("Head")
	if head and head:IsA("BasePart") and hitPosition then
		local localPos = head.CFrame:PointToObjectSpace(hitPosition)
		local margin = 0.6
		if math.abs(localPos.X) <= (head.Size.X * 0.5 + margin)
			and math.abs(localPos.Y) <= (head.Size.Y * 0.5 + margin)
			and math.abs(localPos.Z) <= (head.Size.Z * 0.5 + margin)
		then
			return true
		end
	end

	local hrp = targetCharacter:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") and hitPosition then
		return hitPosition.Y >= (hrp.Position.Y + 1.9)
	end

	return false
end

function FoodCombatManager:Init(Core)
	self.ProjectileManager = Core:Get("ProjectileManager")
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")
	self.FoodServerModuleFolder = ServerScriptService.Modules.Core.FoodServerModules
	self.EnergyManager = Core:Get("EnergyManager")
	self.ComboManager = Core:Get("ComboManager")
	self.FoodModules = {}

	self.UltimatePlayers = {} --list of players whose ultimate is activated

	self.CombatEnabled = true

	for _, module in self.FoodServerModuleFolder:GetChildren() do
		local Name = string.gsub(module.Name, "Server", "")
		self.FoodModules[Name] = Core:Get(module.Name)
	end
end

--Combat replication
function FoodCombatManager:Start()
	self.CombatEvent:Connect(function(player, action, data)
		if self.CombatEnabled == false then
			return
		end

		if action == "Fire" then
			local module = self.FoodModules[data.Combat.FoodName]
			if not module then
				warn("food module not found for ", tostring(data.Combat.FoodName))
				return
			end

			if data.Combat.Ultimate then
				if module.OnFireUltimate then
					module:OnFireUltimate(player, data)
				end
			else
				if module.OnFireNormal then
					module:OnFireNormal(player, data)
				end
			end

			if module.Fire then
				module:Fire(player, data)
			else
				self.CombatEvent:FireExcept(true, { player }, "Fire", data)
			end
		elseif action == "Hit" then
			local module = self.FoodModules[data.Combat.FoodName]
			if not module then
				warn("food module not found for ", tostring(data.Combat.FoodName))
				return
			end

			if data.Combat.Ultimate then
				if module.OnHitUltimate then
					module:OnHitUltimate(player, data)
				end
			else
				if module.OnHitNormal then
					module:OnHitNormal(player, data)
				end
			end

			if module.OnHit then
				module:OnHit(player, data)
			end

			self.CombatEvent:FireExcept(true, { player }, "Hit", data)
						
		elseif action == "ActivateUltimate" then
			return self:ActivateUltimate(player)
		elseif action == "DeactivateUltimate" then
			self:DeactivateUltimate(player)
		end
	end)
end

--Damage Management--

--note: use this function to handle ALL damaging
function FoodCombatManager:DamageCharacter(TargetCharacter: Model, Amount: number, Attacker: Player?, CombatInfo: { Critical: boolean?, Ultimate: boolean?, FoodName: string?, Headshot: boolean? }?)
	if not self.CombatEnabled then
		return
	end --combat disabled means no damage
	if not TargetCharacter then
		warn("no character present to damage ")
		return
	end

	--here, you can check for status effects, and implement other logic to determine whether someone should take damage or not

	local Humanoid = TargetCharacter:FindFirstChild("Humanoid")

	if not Humanoid then
		return
	end

	--handle damage
	--tag humanoid logic--
	if Attacker then
		local CreatorTag = Humanoid:FindFirstChild("creator")
		if CreatorTag and CreatorTag.Value ~= Attacker then
			CreatorTag:Destroy()
			CreatorTag = nil
		end

		if not CreatorTag then
			CreatorTag = Instance.new("ObjectValue")
			CreatorTag.Name = "creator"
			CreatorTag.Value = Attacker
			CreatorTag.Parent = Humanoid
		end
	end

	local comboCount = 0
	local comboMultiplier = 1
	if Attacker then
		comboCount, comboMultiplier = self.ComboManager:Increment(Attacker)
	end

	local headshotMultiplier = (CombatInfo and CombatInfo.Headshot) and 2 or 1
	local finalAmount = Amount * comboMultiplier * headshotMultiplier

	Humanoid:TakeDamage(finalAmount)

	--fire damage dealt event to attacker & damage received to victim(s)

	local TargetPlayer = Players:GetPlayerFromCharacter(TargetCharacter)

	if Attacker then
		self.CombatEvent:Fire(true, Attacker, "DamageDealt", {
			Amount = finalAmount,
			BaseAmount = Amount,
			Combo = {
				Count = comboCount,
				Multiplier = comboMultiplier,
			},
			Headshot = CombatInfo and CombatInfo.Headshot or false,
			HeadshotMultiplier = headshotMultiplier,
			TargetCharacter = TargetCharacter,
			Combat = CombatInfo or {}
		})
	end

	if not TargetPlayer then
		return
	end

	self.ComboManager:Reset(TargetPlayer, "took_damage")

	self.CombatEvent:Fire(true, TargetPlayer, "DamageReceived", {
		Attacker = Attacker,
		Amount = finalAmount,
		BaseAmount = Amount,
		Combat = CombatInfo or {}
	})
end

--Ultimate Stuff
function FoodCombatManager:ActivateUltimate(player) --may need to add custom activation logic
	if
		self.EnergyManager:VerifyUltimate(player)
		and self.CombatEnabled
		and not FoodCombatManager:IsUltimate(player)
	then
		table.insert(self.UltimatePlayers, player)
		print("ultimate activated!")

		self.EnergyManager.PlayerEnergyData[player].CanUltimate = false
		return true
	end
	warn("player cannot use ultimate yet")
	return false
end

function FoodCombatManager:DeactivateUltimate(player)
	if self:IsUltimate(player) then
		print("now deactivating")
		table.remove(self.UltimatePlayers, table.find(self.UltimatePlayers, player))

		self.CombatEvent:Fire(true, player, "DeactivateUltimate")
	end
end

function FoodCombatManager:IsUltimate(player)
	return table.find(self.UltimatePlayers, player) ~= nil and true or false
end

return FoodCombatManager
