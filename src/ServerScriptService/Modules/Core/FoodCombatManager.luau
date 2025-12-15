--Purpose: Manages network function traffic and executing server actions for food combat
--janin 12/10/25

local FoodCombatManager = {}

--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

function FoodCombatManager:Init(Core)
	self.ProjectileManager = Core:Get("ProjectileManager")
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")
	self.FoodServerModuleFolder = ServerScriptService.Modules.Core.FoodServerModules
	self.EnergyManager = Core:Get("EnergyManager")
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
			print(data)
			self.FoodModules[data.Combat.FoodName]:Fire(player, data)
		elseif action == "Hit" then
			self.FoodModules[data.Combat.FoodName]:OnHit(player, data)
		elseif action == "ActivateUltimate" then
			return self:ActivateUltimate(player)
		end
	end)
end

--Damage Management--

--note: use this function to handle ALL damaging
function FoodCombatManager:DamageCharacter(TargetCharacter: Model, Amount: number, Attacker: Player?)
	
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
	Humanoid:TakeDamage(Amount)

	--fire damage dealt event to attacker & damage received to victim(s)

	local TargetPlayer = Players:GetPlayerFromCharacter(TargetCharacter)

	if Attacker then
	self.CombatEvent:Fire(true, Attacker , "DamageDealt", {
		Amount = Amount,
		TargetCharacter = TargetCharacter,
	})

end

	if not TargetPlayer then
		return
	end

	self.CombatEvent:Fire(true, TargetPlayer, "DamageReceived", {
		Attacker = Attacker,
		Amount = Amount,
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
