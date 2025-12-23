--handles the chicken npcs, replication, etc
--this code might have a memory leak lol

local EggServer = {}

--Services--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--Imports--
local UtilFunctions = require(ReplicatedStorage.Modules.Utils.Functions)
local Janitor = require(ReplicatedStorage.Modules.Utils.Janitor)
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
	[playerInstance] = ChickenData
	]]
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

local function SpawnChickenNPC(self: typeof(EggServer), player: Player, data)
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

	local ChickenJanitor = Janitor.new()

	local ChickenData = {
		Model = ChickenNPC,
		Owner = player,
		SpawnTick = tick(),
		LastAttackTime = tick(),
		Janitor = ChickenJanitor,
	}

	table.insert(self.Chickens[player], ChickenData)
	table.insert(self.ChickenModels, ChickenNPC)

	local heartbeatConnection = RunService.Heartbeat:Connect(function()
		if not ChickenNPC.Parent then
			ChickenJanitor:Cleanup()
			return
		end

		local StopMargin = 5
		local ClosestChar = checkNearestPlayer(ChickenNPC.HumanoidRootPart.Position, 300, {})

		if ClosestChar then
			local TargetHRP = ClosestChar.HumanoidRootPart
			local MoveVector = TargetHRP.Position - ChickenNPC.HumanoidRootPart.Position
			local MoveDist = MoveVector.Magnitude
			local MoveDirection = MoveVector.Unit

			if MoveDist > StopMargin then
				ChickenNPC.Humanoid:Move(MoveDirection)
			elseif MoveDist <= StopMargin then
				ChickenNPC.Humanoid:Move(Vector3.zero)

				if tick() - ChickenData.LastAttackTime >= CHICKEN_ATTACK_COOLDOWN then
					ChickenData.LastAttackTime = tick()

					local Params = OverlapParams.new()
					Params.FilterType = Enum.RaycastFilterType.Exclude
					Params.FilterDescendantsInstances = {self.ChickenModels, player.Character}
					local hitCharacters = CreateHitbox(
						CFrame.new(
							ChickenNPC.HumanoidRootPart.Position
								+ ChickenNPC.HumanoidRootPart.CFrame.LookVector * 5
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
			ChickenNPC.Humanoid:Move(Vector3.zero)
		end
	end)

	ChickenJanitor:Add(heartbeatConnection, "Disconnect")
	task.delay(CHICKEN_LIFETIME, function()
		-- send event to client for disappear vfx
		self.CombatEvent:Fire(true, "ChickenCleanup", {
			Sender = player,
			Combat = {
				FoodName = "Egg"
			},
			Position = ChickenNPC.HumanoidRootPart.Position
		})

		ChickenNPC:Destroy()
		ChickenJanitor:Cleanup()
		table.remove(self.Chickens[player], table.find(self.Chickens[player], ChickenData))
	end)
end

function EggServer:OnFireNormal(player, data)
	self.CombatEvent:FireExcept(true, { player }, "Fire", data)
end

function EggServer:OnFireUltimate(player, data)
	self.EnergyManager:Drain(player, self.Config.Energy.AbilityCost)
	self.CombatEvent:FireExcept(true, { player }, "Fire", data)
end

function EggServer:OnHitNormal(player, data)
	local HitCharacter = UtilFunctions.FindCharacter(data.Projectile.HitResult.Instance)
	if HitCharacter then
		self.FoodCombatManager:DamageCharacter(HitCharacter, self.Config.Combat.BaseDamage, player)
	end
	self.CombatEvent:FireExcept(true, { player }, "Hit", data)
end

function EggServer:OnHitUltimate(player, data)
	local HitCharacter = UtilFunctions.FindCharacter(data.Projectile.HitResult.Instance)
	if HitCharacter then
		self.FoodCombatManager:DamageCharacter(HitCharacter, self.Config.Combat.BaseDamage, player)
	end
	self.CombatEvent:FireExcept(true, { player }, "Hit", data)
	SpawnChickenNPC(self, player, data)
end

return EggServer
