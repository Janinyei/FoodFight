--Purpose: Manages energy levels during combat & enables ultimates
--[[
note:
Once people activate their energy, make sure that there's a variable called "ultimateActivated" to
be able to differentiate 


you can have a list like:

[Player] = {
Energy = 0,
MaxEnergy = 1000
}

MaxEnergy - Max Energy needed for ult activation. Changes from food to food
switching foods will reset energy

keep in mind some food ultimates will start working upon activation

I may even make a food that drains other people's energy as its own ability who knows

]]

--Services--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EnergyRate = 3 --per second rate
local EnergyManager = {}

function EnergyManager:Init(Core)
	self.PlayerEnergyData = {}
	self.GameStatusManager = Core:Get("GameStatusManager")
	self.DataManager = Core:Get("DataManager")
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")

	self.FoodCombatManager = Core:Get("FoodCombatManager")
end

function EnergyManager:Start(Core)
	--player/data added & remove events

	self.DataManager.DataLoaded:Connect(function(player, Data)
		local CurrentFood = Data.Inventory.Equipped.Food

		if CurrentFood then
			self.PlayerEnergyData[player] = {
				CurrentFood = CurrentFood,
				Energy = 0,
				MaxEnergy = require(game.ReplicatedStorage.Modules.Info.FoodCombatConfigs[CurrentFood .. "Config"]).Energy.MaxEnergy,
				CanUltimate = false,
				LastUpdateTick = tick(),
			}
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if self.PlayerEnergyData[player] then
			self.PlayerEnergyData[player] = nil
		end
	end)

	--create runservice event that slowly increases all energy (only for players that are active)

	local ActivePlayers = self.GameStatusManager.ActivePlayers
	print(ActivePlayers)

	RunService.Heartbeat:Connect(function(deltaTime)
		for _, plr in self.GameStatusManager.ActivePlayers do
			local CurrentFood = self.PlayerEnergyData[plr] and self.PlayerEnergyData[plr].CurrentFood

			if not CurrentFood then
				continue
			end

			if self.FoodCombatManager:IsUltimate(plr) then
				if self.PlayerEnergyData[plr].Energy <= 0 then
					self.FoodCombatManager:DeactivateUltimate(plr)
					print("ult deactivated")
				end
				continue
			end

			if tick() - self.PlayerEnergyData[plr].LastUpdateTick < 1 then
				continue
			end
			--above is a good usage of guard clauses. It's a nice alternative to nested if statements

			self.PlayerEnergyData[plr].LastUpdateTick = tick()

			--checks if max energy is equal to energy
			if self.PlayerEnergyData[plr].Energy >= self.PlayerEnergyData[plr].MaxEnergy then
				self.PlayerEnergyData[plr].CanUltimate = true
				continue
			end

			local FoodConfig = require(game.ReplicatedStorage.Modules.Info.FoodCombatConfigs[CurrentFood .. "Config"])

			if FoodConfig and FoodConfig.Energy.BoostRate then
				self:Boost(plr, FoodConfig.Energy.BoostRate)
			end
		end
	end)
end

--gives food combat manager the thumbs-up
function EnergyManager:VerifyUltimate(player)
	if self.PlayerEnergyData[player].CanUltimate then
		print(self.PlayerEnergyData[player])
		return true
	end
end
--edit functions

function EnergyManager:SetEnergy(plr, Amount)
	self.PlayerEnergyData[plr].Energy = Amount
	self.FoodCombatManager.CombatEvent:Fire(true, plr, "UpdateEnergy", {
		Energy = Amount,
		MaxEnergy = self.PlayerEnergyData[plr].MaxEnergy
	})
end

function EnergyManager:Boost(plr, Amount)
	local CurrentEnergy = self.PlayerEnergyData[plr].Energy
	local MaxEnergy = self.PlayerEnergyData[plr].MaxEnergy
	
	self:SetEnergy(plr, math.clamp(CurrentEnergy + Amount, 0, MaxEnergy))
	print("new energy amount: ", tostring(self.PlayerEnergyData[plr].Energy))
end

function EnergyManager:Drain(plr, Amount)
	local CurrentEnergy = self.PlayerEnergyData[plr].Energy
	local MaxEnergy = self.PlayerEnergyData[plr].MaxEnergy
	
	print("new energy amount after drain: ", tostring(self.PlayerEnergyData[plr].Energy))

	self:SetEnergy(plr, math.clamp(CurrentEnergy - Amount, 0, MaxEnergy))
end

return EnergyManager
