--handles the chicken npcs, replication, etc
--this code might have a memory leak lol

local EggServer = {}

--Services--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--Imports--
local UtilFunctions = require(ReplicatedStorage.Modules.Utils.Functions)
--variables--
local ChickenModel = ReplicatedStorage.Assets.Food.Egg.Special.Chicken
local CHICKEN_ATTACK_COOLDOWN = 0.5
local CHICKEN_LIFETIME = 3
--constants--

--return list of hit characters
local function CreateHitbox(cf: Cframe, Size: Vector3, Params: OverlapParams): { Model }
	local Instances = workspace:GetPartBoundsInBox(cf, Size, Params)
	local tbl = {}

	print(Instances)

	for _, obj in Instances do
		local character, plr = UtilFunctions.FindCharacter(obj)
		if character and not table.find(tbl, character) then
			table.insert(tbl, character)
		end
	end
	return tbl
end
--
function EggServer:Init(Core)
	self.ProjectileManager = Core:Get("ProjectileManager")
	self.Config = require(ReplicatedStorage.Modules.Info.FoodCombatConfigs.EggConfig)
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")
	self.CollisionGroupManager = Core:Get("CollisionGroupManager")
	self.FoodCombatManager = Core:Get("FoodCombatManager")
	self.EnergyManager = Core:Get("EnergyManager")
	self.Chickens = {}
	self.ChickenModels = {} --only used for hitbox filtering

	--[[
	[playerInstance] = ChickenModel
	]]

	self:UpdateChickenNPCs()
end

local function checkNearestPlayer(pos: Vector3, Range: number, ignoreList: { Player }?): Model
	local ClosestDist = nil
	local ClosestChar = nil
	local PlayerList = Players:GetPlayers()

	for _, player in PlayerList do
		if ignoreList and table.find(ignoreList, player) ~= nil then
			continue
		end
		local TargetCharacter = player.Character or player.CharacterAdded:Wait()

		local TargetDistance = (TargetCharacter.HumanoidRootPart.Position - pos).Magnitude

		if TargetDistance <= Range then
			if ClosestDist == nil or TargetDistance < ClosestDist then
				ClosestChar = TargetCharacter
				ClosestDist = (ClosestChar.HumanoidRootPart.Position - pos).Magnitude
			end
		end
	end

	return ClosestChar
end

function EggServer:Fire(player, data)
	
	if self.FoodCombatManager:IsUltimate(player) then
	self.EnergyManager:Drain(player, self.Config.Energy.AbilityCost) --drain energy
	end
	--self.ProjectileManager:HandleFireProjectile(player, data.Projectile) -- replicate fire here too
	self.CombatEvent:FireExcept(true, { player }, "Fire", data)
end

function EggServer:OnHit(player, data)

	local isSpecial = data.Combat.Ultimate
	--perform sanity check--
	--local CanHit = self.ProjectileManager:ValidateHit(player, data.Projectile)
	local CanHit = true
	if CanHit then
		print(player)

		--do some damage to someone

		print(data.Projectile.HitResult.Instance)

		local HitCharacter, isPlayer = UtilFunctions.FindCharacter(data.Projectile.HitResult.Instance)

		print(HitCharacter)

		if HitCharacter then
			self.FoodCombatManager:DamageCharacter(HitCharacter, self.Config.Combat.BaseDamage, player)
		end
		--note : I can pass through different arguments for the damage indicator so I can control GUI
		self.CombatEvent:FireExcept(true, { player }, "Hit", data)
	end

	if isSpecial then


		print("spawn chickens")
		if not self.Chickens[player] then
			self.Chickens[player] = {}
		end

		local ChickenNPC = ChickenModel:Clone()
		ChickenNPC.Parent = workspace
		local spawnPoint = data.Projectile.HitResult.Position + Vector3.new(0, 1, 0)
		ChickenNPC.HumanoidRootPart.CFrame = CFrame.new(spawnPoint)
		ChickenNPC.Humanoid.WalkSpeed = 32
		self.CollisionGroupManager:NoclipModel(ChickenNPC)

		local ChickenData = {
			Model = ChickenNPC,
			Owner = player,
			SpawnTick = tick(),
			LastAttackTime = tick(),
		}

		table.insert(self.Chickens[player], ChickenData)
		table.insert(self.ChickenModels, ChickenNPC)
		
		task.delay(CHICKEN_LIFETIME, function()



			--send event to client for disappear vfx
			self.CombatEvent:Fires(true, "ChickenCleanup", {
					Sender = player,
					Combat = {
						FoodName = "Egg"
					},
					Position = ChickenNPC.HumanoidRootPart.Position
				
			} ) --i js realized it's not gonna work if you don't specify the type of food lol

			ChickenNPC:Destroy()
		
			table.remove(self.Chickens[player], table.find(self.Chickens[player], ChickenData ))
		end)
	end
end

function EggServer:UpdateChickenNPCs()
	RunService.Heartbeat:Connect(function()
		local StopMargin = 5
		--note: could use a module that has a function called "GetDamageBlackList" which dynamically returns players that should not be damaged by another player. This includes the player who attacks as well.
		for player, ChickenObjects in self.Chickens do
			for _, ChickenObjData in ChickenObjects do
				local chickenModel = ChickenObjData.Model
				local ClosestChar = checkNearestPlayer(chickenModel.HumanoidRootPart.Position, 300, {}) --blacklisting allows for ignoring teammates and/or the attacker

				--follow  closest player
				if ClosestChar then
					local TargetHRP = ClosestChar.HumanoidRootPart
					--print(CurrentClosestChar.Name)
					local MoveVector = TargetHRP.Position - chickenModel.HumanoidRootPart.Position
					local MoveDist = MoveVector.Magnitude
					local MoveDirection = MoveVector.Unit
					--

					--this npc needs to be smarter lol
					if MoveDist > StopMargin then
						chickenModel.Humanoid:Move(MoveDirection)
					elseif MoveDist <= StopMargin then
						chickenModel.Humanoid:Move(Vector3.zero)
						--attack here--

						if tick() - ChickenObjData.LastAttackTime >= CHICKEN_ATTACK_COOLDOWN then
							ChickenObjData.LastAttackTime = tick()

							local Params = OverlapParams.new()
							Params.FilterType = Enum.RaycastFilterType.Exclude
							Params.FilterDescendantsInstances = {self.ChickenModels, player.Character}
							local hitCharacters = CreateHitbox(
								CFrame.new(
									chickenModel.HumanoidRootPart.Position
										+ chickenModel.HumanoidRootPart.CFrame.LookVector * 5
								),
								Vector3.new(10, 10, 10),
								Params
							)

							for _, hitCharacter in hitCharacters do
						
								self.FoodCombatManager:DamageCharacter(hitCharacter, self.Config.Combat.ChickenDamage, player)
							end
						end
					end
				else
					chickenModel.Humanoid:Move(Vector3.zero)
				end
			end
		end
	end)
end



return EggServer
