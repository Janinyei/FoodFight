--Purpose: Centralized controller for food attacks &  effects replication. Connects to other food modules to support a modular design
-- janin 12/10/25

--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CAS = game:GetService("ContextActionService")

--Modules--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils

--Imports--
local Signal = require(Utils.Signal)

--Variables--
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local FoodModels = ReplicatedStorage.Assets.FoodModels

local FoodModuleFolder = script.Parent.Food

local FoodCombatController = {}

--setup dependencies, events, signals, remotes, etc
function FoodCombatController:Init(Core)
	self.CurrentFood = nil -- The food the player is currently holding/using

	--modules--
	self.ClientDataController = Core:Get("ClientDataController") --concurrent data
	self.ProjectileController = Core:Get("ProjectileController")
	self.TrajectoryBeam = Core:Get("TrajectoryBeam") --predictive aiming
	self.CameraController = Core:Get("CameraController")
	self.CharacterController = Core:Get("CharacterController")
	self.InputController = Core:Get("InputController")

	--local variables
	self.UltimateActivated = false
	self.CanUltimate = false
	self.CurrentEnergy = 0 -- on the server after using a move that costs energy, use the remote to update this value in order to make gameplay smoother, so the client doesn't rely on the server-sided check
	self.LastFired = tick() -- for cooldown
	--serves to: 1. update energy GUI 2. Prevent players from launching attacks

	--events
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")

	--signals--
	self.EnergyChanged = Signal.new()
	self.DamageDealt = Signal.new()
	self.DamageReceived = Signal.new()

	--loading food modules--
	self.FoodModules = {}

	self.ClientDataController.InventoryChanged:Connect(function(Inventory)
		self.CurrentFood = Inventory.Equipped.Food
	end)

	for _, module in FoodModuleFolder:GetChildren() do
		local Name = string.gsub(module.Name, "Client", "")
		self.FoodModules[Name] = require(module)
	end
end

--setup input for aiming and attacking
function FoodCombatController:Start()
	local CombatAction = "Combat"

	local function handleProjectile(actionName, inputState, inputObject)
		--check character instances
		if LocalPlayer.Character == nil then
			return
		end

		local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not HRP then
			return
		end

		if actionName ~= CombatAction then
			return
		end

		if inputState == Enum.UserInputState.Begin then
			if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
				if
					tick() - self.LastFired
					>= require(Modules.Info.FoodCombatConfigs[self.CurrentFood .. "Config"]).Combat.Cooldown
				then
					self.LastFired = tick()
					self:Fire()
				end
			elseif inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
				self.CameraController:ToggleAimZoom(true)
				self:StartAim()
			elseif inputObject.KeyCode == Enum.KeyCode.E then
				self:ActivateUltimate(LocalPlayer)
			end
		elseif inputState == Enum.UserInputState.End then
			if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
				self:StopAim()
			self.CameraController:ToggleAimZoom(false)
			end
		end
	end

	CAS:BindAction(
		CombatAction,
		handleProjectile,
		false,
		Enum.UserInputType.MouseButton1,
		Enum.UserInputType.MouseButton2,
		Enum.KeyCode.E
	)

	--setup replication--

	self:StartReplication()
end

--Aiming Functionality--
function FoodCombatController:StartAim()
	local FoodModule = self.FoodModules[self.CurrentFood]
	local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	
	self.CharacterController.ParkourConfig.rotateHRPWithCamera = true

	if self.FoodModules[self.CurrentFood].Aim then
		self.FoodModules[self.CurrentFood]:Aim()
		return
	end

	self.TrajectoryBeam:Enable(function()
		return {
			Origin = HRP.Position,
			Velocity = ((Mouse.Hit.Position - HRP.Position).Unit * FoodModule.Config.Projectile.Speed)
				+ (FoodModule.Config.Projectile.InitUpwardVelocity or Vector3.zero),
			Gravity = self.FoodModules[self.CurrentFood].Config.Projectile.Acceleration,
			RaycastParams = self.ProjectileController.RaycastParams,
		}
	end)
end

function FoodCombatController:StopAim()
	self.CharacterController.ParkourConfig.rotateHRPWithCamera = false
	if self.FoodModules[self.CurrentFood].StopAim then
		self.FoodModules[self.CurrentFood]:StopAim()
		return
	end

	self.TrajectoryBeam:Disable()
end

--requests to server to activate ultimate ability
function FoodCombatController:ActivateUltimate()
	local CanActivateUlt = self.CombatEvent:Invoke(10, "ActivateUltimate")

	print(CanActivateUlt)
	if CanActivateUlt then
		self.UltimateActivated = true
		print("ultimate activation success")
		--insert script if any food has custom usage logic
		--do something like OnUltimateActivated or smtn idk
	end
end

--basic attack function
function FoodCombatController:Fire()
	--[[cooldown
   local cooldown = ProjectileData.Cooldown or 1
      if self.ProjectileCooldowns[FoodName] and currentTime - self.ProjectileCooldowns[FoodName] < cooldown then
         return
      end
]]

	local FoodModule = self.FoodModules[self.CurrentFood]
	local ProjectileConfig = FoodModule.Config.Projectile

	if self.FoodModules[self.CurrentFood].Fire then
		self.FoodModules[self.CurrentFood]:Fire()
		return --guard clause
	end

	local FireData = {
		Sender = LocalPlayer,
		Combat =  {
			FoodName = self.CurrentFood,
			isUltimate = self.UltimateActivated,

		},

		Projectile = {	
			
			Owner = LocalPlayer,
			Origin = LocalPlayer.Character.HumanoidRootPart.Position,
			Velocity = (Mouse.Hit.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * ProjectileConfig.Speed
				+ (ProjectileConfig.InitUpwardVelocity or Vector3.zero),
			Acceleration = ProjectileConfig.Acceleration,
			MaxBounces = ProjectileConfig.MaxBounces,
			RaycastParams = self.ProjectileController.RaycastParams,
			--IncludeModelInCleanup = ProjectileConfig.IncludeModelInCleanup
		}}

		
	local Projectile = self.ProjectileController:FireProjectile(FoodModels[self.CurrentFood]:Clone(), FireData.Projectile )

	FireData.Projectile.Id = Projectile:GetData().Id --adds more data to the projectile
	FireData.Projectile.RaycastParams = nil --prevents from being replicated so the remote event won't error. Kinda annoying that roblox doesn't replicate RaycastParams but whatever
	if FoodModule.OnFire then --additional logic to default projectiles
		FoodModule:OnFire(FireData)
	end

	
	print(Projectile:GetData())
	
	self.CombatEvent:Fire(true, "Fire", FireData)

	Projectile.OnHit:Connect(function(HitResult)
		if FoodModule.OnHit then
			local hitData = {
				Sender = LocalPlayer,
				Combat = {
					
					FoodName = "Banana",
					Ultimate = self.UltimateActivated,
				},
				Projectile = {
					Id = Projectile.Id,
					HitResult = {
						Instance = HitResult.Instance,
						Position = HitResult.Position,
						Normal = HitResult.Normal,
					},
				},
			}

			FoodModule:OnHit(LocalPlayer, hitData)

			--replicate to server
			self.CombatEvent:Fire(true, "Hit", hitData)
		end
	end)


	Projectile.OnDestroyed:Connect(function(proj)
		local ProjModel = proj.Model
		if ProjModel then
			--this woudl only work if it was a basepart or special mesh etc, so i needa make it work with models
			ProjModel.Anchored = false
			ProjModel.CanCollide = true
		end
	end)
end

--Attack Hit--
function FoodCombatController:OnHit(player, data)
	local AttackerFood = data.Combat.FoodName
	local FoodClientModule = self.FoodModules[AttackerFood]
	if not FoodClientModule.OnHit then
		return
	end
	
	FoodClientModule:OnHit(data)
end

-- Replication Functions--
--on attack replicated
function FoodCombatController:FireReplicated(data)
	local AttackerFood = data.Combat.FoodName
	local FoodClientModule = self.FoodModules[AttackerFood]
	
	if FoodClientModule.FireReplicated then
	FoodClientModule:FireReplicated(data) --runs custom fire replicate function
	else
		self.ProjectileController:FireProjectile(FoodModels[self.CurrentFood]:Clone() ,data.Projectile) --otherwise handle default implementation
	end

	if FoodClientModule.OnFireReplicated then
		FoodClientModule:OnFireReplicated(data)
	end
end

--on hit replicated
function FoodCombatController:OnHitReplicated(data)
	local AttackerFood = data.Combat.FoodName
	local FoodClientModule = self.FoodModules[AttackerFood]

	if  FoodClientModule.OnHitReplicated then  
	FoodClientModule:OnHitReplicated(data)
	end
end

--handles general combat replication
function FoodCombatController:StartReplication()
	self.CombatEvent:Connect(function(action, data)
		if action == "Fire" then
			self:FireReplicated(data)
		elseif action == "Hit" then
			self:OnHitReplicated(data)
		elseif action == "DeactivateUltimate" then
			print("ultimate deactivated from client")
			self.UltimateActivated = false
		elseif action == "UpdateEnergy" then
			self.CurrentEnergy = data.Energy
			--print("energy replicated to client: " .. data.Energy)
			self.EnergyChanged:Fire(data)
		elseif action == "DamageDealt" then --received by a  player who did some damage
			--use to:
			-- Display damage numbers
			-- Activate Hitmarker
			print("handling damage dealt effects")
			self.DamageDealt:Fire(data)
		elseif action == "Damaged" then --received by a player who got hit
			--use to:
			--activate damage indicator
			self.DamageReceived:Fire(data)
		else
			print(action, data)
			self:HandleSpecialAction(action, data)
			--pass up to custom action management
		end
	end)
end

--sets up even more custom functionality
function FoodCombatController:HandleSpecialAction(action: string, data)
	local FoodClientModule = self.FoodModules[data.Combat.FoodName]
	if not FoodClientModule.HandleAction then
		return
	end
	FoodClientModule:HandleAction(action, data)
end

--helpers--
function FoodCombatController:GetFoodModule(FoodName: string)
	if self.FoodModules[FoodName] then
		return self.FoodModules[FoodName]
	else
		warn("food client module not found for " .. FoodName)
	end
end

return FoodCombatController
