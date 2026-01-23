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
local Functions = require(Utils.Functions)
local Effects = Modules.Effects
local FoodSplat = require(Effects.FoodSplat)
local PoofClouds = require(Effects.PoofClouds)

--Variables--
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local FoodModels = ReplicatedStorage.Assets.FoodModels

local FoodModuleFolder = script.Parent.Food

local FoodCombatController = {}

local function getModelColor(model: Model | BasePart): Color3?
	if model:IsA("BasePart") then
		return model.Color
	end

	local part = model:FindFirstChildWhichIsA("BasePart", true)
	return part and part.Color or nil
end

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
	self.IsUltimateActive = false
	self.CanUltimate = false
	self.CurrentEnergy = 0 -- on the server after using a move that costs energy, use the remote to update this value in order to make gameplay smoother, so the client doesn't rely on the server-sided check
	self.LastNormalFired = tick()
	self.LastUltimateFired = tick()
	--serves to: 1. update energy GUI 2. Prevent players from launching attacks

	--events
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")

	--signals--
	self.EnergyChanged = Signal.new()
	self.DamageDealt = Signal.new()
	self.DamageReceived = Signal.new()
	self.UltimateActivated = Signal.new()
	self.UltimateDeactivated = Signal.new()
	self.Fired = Signal.new()
	self.PlayerEliminated = Signal.new()
	self.ProjectileHitLocal = Signal.new()

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
				self:HandleNormalAttack()
			elseif inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
				self.CameraController:ToggleAimZoom(true)
				self:StartAim()
			elseif inputObject.KeyCode == Enum.KeyCode.E then
				self:HandleUltimateActivation()
			end
		elseif inputState == Enum.UserInputState.End then
			if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
				self:StopAim()
				self.CameraController:ToggleAimZoom(false)
			end
		end
		
		return Enum.ContextActionResult.Pass
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
	
	if self._prevRotateHRPWithCamera == nil and self.CharacterController and self.CharacterController.ParkourConfig then
		self._prevRotateHRPWithCamera = self.CharacterController.ParkourConfig.rotateHRPWithCamera
	end
	self.CharacterController.ParkourConfig.rotateHRPWithCamera = true

	if self.FoodModules[self.CurrentFood].Aim then
		self.FoodModules[self.CurrentFood]:Aim()
		return
	end

	--[[self.TrajectoryBeam:Enable(function()
		return {
			Origin = HRP.Position,
			Velocity = ((Mouse.Hit.Position - HRP.Position).Unit * FoodModule.Config.Projectile.Speed)
				+ (FoodModule.Config.Projectile.InitUpwardVelocity or Vector3.zero),
			Gravity = self.FoodModules[self.CurrentFood].Config.Projectile.Acceleration,
			RaycastParams = self.ProjectileController.RaycastParams,
		}
	end)]]

end

function FoodCombatController:StopAim()
	if self._prevRotateHRPWithCamera ~= nil then
		self.CharacterController.ParkourConfig.rotateHRPWithCamera = self._prevRotateHRPWithCamera
	else
		self.CharacterController.ParkourConfig.rotateHRPWithCamera = true
	end
	self._prevRotateHRPWithCamera = nil
	if self.FoodModules[self.CurrentFood].StopAim then
		self.FoodModules[self.CurrentFood]:StopAim()
		return
	end

	self.TrajectoryBeam:Disable()
end

function FoodCombatController:HandleUltimateActivation()
	if self.IsUltimateActive then
		self.CombatEvent:Fire(true, "DeactivateUltimate")
		return
	end

	local CanActivateUlt = self.CombatEvent:Invoke(10, "ActivateUltimate")

	if CanActivateUlt then
		self.IsUltimateActive = true
		self.LastUltimateFired = tick()
		
		local FoodModule = self.FoodModules[self.CurrentFood]
		if FoodModule and FoodModule.OnUltimateActivated then
			FoodModule:OnUltimateActivated()
		end
		
		self.UltimateActivated:Fire()
	end
end

function FoodCombatController:HandleNormalAttack()
if self.IsUltimateActive then
		self:FireUltimate()
		return
	end

	local FoodConfig = require(Modules.Info.FoodCombatConfigs[self.CurrentFood .. "Config"])
	if tick() - self.LastNormalFired >= FoodConfig.Combat.Cooldown then
		self.LastNormalFired = tick()
		self:FireNormal()
	end
end

function FoodCombatController:FireNormal()
	local FoodModule = self.FoodModules[self.CurrentFood]
	local ProjectileConfig = FoodModule.Config.Projectile

	if FoodModule.FireNormal then
		FoodModule:FireNormal()
		return
	end

	local FireData = {
		Sender = LocalPlayer,
		Combat = {
			FoodName = self.CurrentFood,
			Ultimate = false,
		},
		Projectile = {	
			Owner = LocalPlayer,
			Origin = LocalPlayer.Character.HumanoidRootPart.Position,
			Velocity = (Mouse.Hit.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * ProjectileConfig.Speed
				+ (ProjectileConfig.InitUpwardVelocity or Vector3.zero),
			Acceleration = ProjectileConfig.Acceleration,
			MaxBounces = ProjectileConfig.MaxBounces,
			RaycastParams = self.ProjectileController.RaycastParams,
			MaxHits = ProjectileConfig.MaxHits,
			DestroyOnHit = ProjectileConfig.DestroyOnHit or false
		}
	}

	local Projectile = self.ProjectileController:FireProjectile(FoodModels[self.CurrentFood]:Clone(), FireData.Projectile)

	FireData.Projectile.Id = Projectile:GetData().Id
	FireData.Projectile.RaycastParams = nil

	if FoodModule.OnFireNormal then
		FoodModule:OnFireNormal(FireData)
	end

	print(Projectile:GetData())

	self.CombatEvent:Fire(true, "Fire", FireData)
	self.Fired:Fire(FireData)

	Projectile.OnHit:Connect(function(HitResult)
		if FoodModule.OnHitNormal then
			local hitData = {
				Sender = LocalPlayer,
				Combat = {
					FoodName = self.CurrentFood,
					Ultimate = false,
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

			FoodModule:OnHitNormal(LocalPlayer, hitData)
			self.CombatEvent:Fire(true, "Hit", hitData)
		else
			local hitData = {
				Sender = LocalPlayer,
				Combat = {
					FoodName = self.CurrentFood,
					Ultimate = false,
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
			
			local character = Functions.FindCharacter(HitResult.Instance)
			if character then
				self.ProjectileHitLocal:Fire({
					Character = character,
					HitResult = HitResult,
					Combat = hitData.Combat,
				})
				self.CameraController:Shake("FoodHit")
			else
				FoodSplat:Play({
					Obj = HitResult.Instance,
					Position = HitResult.Position,
					Normal = HitResult.Normal,
					Radius = math.clamp((Projectile.HitRadius or 1) * 3, 2, 6),
					Color = getModelColor(Projectile.Model),
				})
			end

			self.CombatEvent:Fire(true, "Hit", hitData)
		end
	end)

	Projectile.OnDestroyed:Connect(function(proj)
		local ProjModel = proj.Model
		if ProjModel then
			ProjModel.Anchored = false
			ProjModel.CanCollide = true
		end
	end)
end

function FoodCombatController:FireUltimate()
	local FoodModule = self.FoodModules[self.CurrentFood]
	local ProjectileConfig = FoodModule.Config.Projectile

	if FoodModule.FireUltimate then
		FoodModule:FireUltimate()
		return
	end

	local FireData = {
		Sender = LocalPlayer,
		Combat = {
			FoodName = self.CurrentFood,
			Ultimate = true,
		},
		Projectile = {	
			Owner = LocalPlayer,
			Origin = LocalPlayer.Character.HumanoidRootPart.Position,
			Velocity = (Mouse.Hit.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * ProjectileConfig.Speed
				+ (ProjectileConfig.InitUpwardVelocity or Vector3.zero),
			Acceleration = ProjectileConfig.Acceleration,
			MaxBounces = ProjectileConfig.MaxBounces,
			RaycastParams = self.ProjectileController.RaycastParams,
			MaxHits = ProjectileConfig.MaxHits,
			DestroyOnHit = (FoodModule.Config.Ultimate and FoodModule.Config.Ultimate.DestroyOnHit) or false
		}
	}

	local Projectile = self.ProjectileController:FireProjectile(FoodModels[self.CurrentFood]:Clone(), FireData.Projectile)

	FireData.Projectile.Id = Projectile:GetData().Id
	FireData.Projectile.RaycastParams = nil

	if FoodModule.OnFireUltimate then
		FoodModule:OnFireUltimate(FireData)
	end

	print(Projectile:GetData())

	self.CombatEvent:Fire(true, "Fire", FireData)
	self.Fired:Fire(FireData)

	Projectile.OnHit:Connect(function(HitResult)
		if FoodModule.OnHitUltimate then
			local hitData = {
				Sender = LocalPlayer,
				Combat = {
					FoodName = self.CurrentFood,
					Ultimate = true,
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

			FoodModule:OnHitUltimate(LocalPlayer, hitData)
			self.CombatEvent:Fire(true, "Hit", hitData)
		else
			-- Always send the Hit event to the server even if client module doesn't handle it
			local hitData = {
				Sender = LocalPlayer,
				Combat = {
					FoodName = self.CurrentFood,
					Ultimate = true,
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
			
			local character = Functions.FindCharacter(HitResult.Instance)
			if character then
				self.ProjectileHitLocal:Fire({
					Character = character,
					HitResult = HitResult,
					Combat = hitData.Combat,
				})
				PoofClouds:Play({ Position = HitResult.Position })
				self.CameraController:Shake("FoodHit")
			else
				FoodSplat:Play({
					Obj = HitResult.Instance,
					Position = HitResult.Position,
					Normal = HitResult.Normal,
					Radius = math.clamp((Projectile.HitRadius or 1) * 4, 3, 8),
					Color = getModelColor(Projectile.Model),
				})
			end

			self.CombatEvent:Fire(true, "Hit", hitData)
		end
	end)

	Projectile.OnDestroyed:Connect(function(proj)
		local ProjModel = proj.Model
		if ProjModel then
			ProjModel.Anchored = false
			ProjModel.CanCollide = true
		end
	end)
end

function FoodCombatController:Fire()
	self:HandleNormalAttack()
end


-- Replication Functions--
--on attack replicated
function FoodCombatController:FireReplicated(data)
	local AttackerFood = data.Combat.FoodName
	local FoodClientModule = self.FoodModules[AttackerFood]
	
	if FoodClientModule.FireReplicated then
	FoodClientModule:FireReplicated(data) --runs custom fire replicate function
	else
		self.ProjectileController:FireProjectile(FoodModels[AttackerFood]:Clone() ,data.Projectile) --otherwise handle default implementation
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
			self.IsUltimateActive = false
			
			local FoodModule = self.FoodModules[self.CurrentFood]
			if FoodModule and FoodModule.OnUltimateDeactivated then
				FoodModule:OnUltimateDeactivated()
			end
			
			self.UltimateDeactivated:Fire(data)
		elseif action == "UpdateEnergy" then
			self.CurrentEnergy = data.Energy
			self.EnergyChanged:Fire(data)
		elseif action == "DamageDealt" then
			print("handling damage dealt effects")
			self.DamageDealt:Fire(data)
		elseif action == "DamageReceived" then
			print("handling damage received effects")
			self.DamageReceived:Fire(data)
		elseif action == "DestroyableHit" then
			self:HandleDestroyableHit(data)
		else
			print(action, data)
			self:HandleSpecialAction(action, data)
			--pass up to custom action management
		end
	end)
end

function FoodCombatController:HandleDestroyableHit(data)
	if data.Type == "Barrel" then
		local explosionPos = data.Position
		local model = data.Model

		if model then
			for _, descendant in ipairs(model:GetDescendants()) do
				if descendant:IsA("ParticleEmitter") then
					descendant:Emit(descendant:GetAttribute("EmitCount") or 20)
				end
			end
		end

		local char = LocalPlayer.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local distance = (char.HumanoidRootPart.Position - explosionPos).Magnitude
			local maxShakeDistance = 50

			if distance <= maxShakeDistance then
				self.CameraController:Shake("Explosion")
			end
		end
	end
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
