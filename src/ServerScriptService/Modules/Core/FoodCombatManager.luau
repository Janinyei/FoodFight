--Purpose: Manages network function traffic and executing server actions for food combat
--janin 12/10/25

local FoodCombatManager = {}

--Services--
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

function FoodCombatManager:Init(Core)
	self.ProjectileManager = Core:Get("ProjectileManager")
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")
	self.FoodServerModuleFolder = ServerScriptService.Modules.Core.FoodServerModules
	self.EnergyManager = Core:Get("EnergyManager")
	self.ComboManager = Core:Get("ComboManager")
	self.DamageHistory = {
		--[[Player] = { 
		[Player] = {
		
		}
		}]]
	}

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

			local hitInstance = data.Projectile and data.Projectile.HitResult and data.Projectile.HitResult.Instance
			if hitInstance then
				local model = hitInstance:FindFirstAncestorWhichIsA("Model")
				if model and CollectionService:HasTag(model, "Destroyable") and model.Name == "Barrel" then
					self:ProcessDestroyableHit(player, model, data.Projectile.HitResult.Position)
				end
			end

			self.CombatEvent:FireExcept(true, { player }, "Hit", data)
		elseif action == "ActivateUltimate" then
			return self:ActivateUltimate(player)
		elseif action == "DeactivateUltimate" then
			self:DeactivateUltimate(player)
		end
	end)
end

-----------------------------------------Damage/Elimination Management--

--note: use this function to handle ALL damaging
function FoodCombatManager:DamageCharacter(
	TargetCharacter: Model,
	Amount: number,
	Attacker: Player?,
	CombatInfo: {
		Critical: boolean?,
		Ultimate: boolean?,
		FoodName: string?,
		Headshot: boolean?,
	}?
)
	if not self.CombatEnabled then
		return
	end --combat disabled means no damage
	if not TargetCharacter then
		warn("no character present to damage ")
		return
	end

	--here, you can check for status effects, and implement other logic to determine whether someone should take damage or not

	local TargetPlayer = Players:GetPlayerFromCharacter(TargetCharacter)
	local Humanoid = TargetCharacter:FindFirstChild("Humanoid")

	if not Humanoid then
		return
	end

	--handle damage
	--tag humanoid logic--
	if Attacker and TargetPlayer then
		local DamageHistory = self.DamageHistory[TargetPlayer]

		if not DamageHistory then
			self.DamageHistory[TargetPlayer] = {}
		end

		--make sure to wipe when target dies or when round ends
		local AttackerHistory = self.DamageHistory[TargetPlayer][Attacker]

		if not AttackerHistory then
			self.DamageHistory[TargetPlayer][Attacker] = {
				DamageAmount = 0,
				CombatInfo.FoodName,
			}
		end

		

		self.DamageHistory[TargetPlayer][Attacker].DamageAmount += 1
		self.DamageHistory[TargetPlayer][Attacker].Time = os.clock()
	end

	local comboCount = 0
	local comboMultiplier = 1
	if Attacker then
		comboCount, comboMultiplier = self.ComboManager:Increment(Attacker)
	end

	local headshotMultiplier = (CombatInfo and CombatInfo.Headshot) and 1.5 or 1
	local finalAmount = Amount * comboMultiplier * headshotMultiplier

	Humanoid:TakeDamage(finalAmount)

	--fire damage dealt event to attacker & damage received to victim(s)

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
			Combat = CombatInfo or {},
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
		Combat = CombatInfo or {},
	})
end

--process elimination and return elimination data 
function FoodCombatManager:ProcessElimination(player) : {}
    local DamageHistory = self.DamageHistory[player]
    
    if not DamageHistory then return end

    local Killer = nil
    local AssistantCandidates = {}
    local Assistants = {}
    
    local LatestTime = -999
    local Now = os.clock()

    -- Constants
    local damageWindow = 15 
    local maxAssistants = 2 

    -- 1. Identify Killer and potential candidates
    for attackingPlr, damageData in pairs(DamageHistory) do
        -- damageData structure: {Amount = number, Time = number, FoodName = string}
        local timeSinceHit = Now - damageData.Time

        if timeSinceHit <= damageWindow then
            -- The person who hit most recently is the Killer
            if damageData.Time > LatestTime then
                -- If we already had a "Killer", move them to assistant candidates
                if Killer then
                    table.insert(AssistantCandidates, {Player = Killer, Amount = DamageHistory[Killer].Amount})
                end
                
                Killer = attackingPlr
                LatestTime = damageData.Time
            else
                -- Otherwise, they are an assistant candidate
                table.insert(AssistantCandidates, {Player = attackingPlr, Amount = damageData.Amount})
            end
        end
    end

    -- 2. Sort Assistant Candidates by Damage (Highest to Lowest)
    table.sort(AssistantCandidates, function(a, b)
        return a.Amount > b.Amount
    end)

    -- 3. Pick the top X assistants
    for i = 1, math.min(#AssistantCandidates, maxAssistants) do
        table.insert(Assistants, AssistantCandidates[i].Player)
    end

    -- 4. Fire to all clients
    -- We send the Victim, Killer, Assistants, and the weapon used (from the killer's data)
    local weaponUsed = Killer and DamageHistory[Killer].FoodName 
	local EliminationData = {
		   Victim = player,
		   Killer = Killer,
		   Assistants = Assistants,
		   Weapon = weaponUsed,
		   IsHeadshot = false -- You can pass this through if you track it in damageData
	   }
    
    self.CombatEvent:FireAllClients("Elimination", EliminationData)


	--Increase Points--
	self.MatchStatsManager:Increment(Killer, "Points", 100)

	self.KillEffectsManager:StartKillEffect(player, EliminationData)

	--assistants

	for _, plr in Assistants do
		self.MatchStatsManager:Increment(plr, "Points", 50)
	end

    -- 5. Cleanup
    self.DamageHistory[player] = nil

	return EliminationData
end

function FoodCombatManager:IsHeadshot(targetCharacter: Model, hitPosition: Vector3?, hitInstance: Instance?)
	local head = targetCharacter:FindFirstChild("Head")
	if head and head:IsA("BasePart") and hitPosition then
		local localPos = head.CFrame:PointToObjectSpace(hitPosition)
		local margin = 0.6
		if
			math.abs(localPos.X) <= (head.Size.X * 0.5 + margin)
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

--------------------------------------------[[Ultimate Stuff]]---------------
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

------------------------------------------[[Prop Destruction]]-------------------------------------
function FoodCombatManager:ProcessDestroyableHit(attacker: Player, model: Model, hitPosition: Vector3)
	self.CombatEvent:Fires(true, "DestroyableHit", {
		Type = "Barrel",
		Position = hitPosition,
		Model = model,
	})

	local explosionRadius = 15
	local knockbackForce = 50

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		local character = otherPlayer.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local hrp = character.HumanoidRootPart
			local distance = (hrp.Position - hitPosition).Magnitude

			if distance <= explosionRadius then
				local direction = (hrp.Position - hitPosition).Unit
				if distance < 0.1 then
					direction = Vector3.new(0, 1, 0)
				end

				local velocity = (direction + Vector3.new(0, 0.5, 0)).Unit
					* knockbackForce
					* (1 - (distance / explosionRadius))
				hrp.AssemblyLinearVelocity = velocity

				-- self:ApplyRagdoll(character, 2)
				-- self:DamageCharacter(character, 20, attacker, { FoodName = "Explosion", Critical = false })
			end
		end
	end
end

return FoodCombatManager
