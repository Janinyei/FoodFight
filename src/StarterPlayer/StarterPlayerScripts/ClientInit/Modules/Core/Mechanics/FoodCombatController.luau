--Purpose: Centralized controller for food attacks &  effects replication. Connects to other food modules to support a modular design
-- janin 12/10/25

--[[
design logic/pseudocode:
Player uses input :
if foodEquipped then
     if input == ShootButton then
         if foodHasCustomFireFunction then
            foodFireFunction()
         else
            defaultFireFunction()
         end
        end

    elseif input == AimButton then
        if foodHasCUstomAimFunction then
                    foodAimFunction()
                 else
                    defaultAimFunction()
                 end
                end
    end


    so, this module essentially handles the base action for combat
    when fire() is called, food may have custom functionality such as a multishot, or may have custom behavior mid flight using :Update()

    let's say I want my grapes to fire three times regularly. In that case, I'll override the default behavior of just one projectile, and handle the firing from the Grape module
    
    the projectileManager on the server still does its typical sanity checks for each individual projectile

    cooldowns are handled here instead



]]

--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CAS = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

--Modules--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils

--Imports--
local Signal = require(Utils.Signal)
local Projectile = require(Utils.Projectile)

--Variables--
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local FoodModels = ReplicatedStorage.Assets.FoodModels

local FoodModuleFolder = script.Parent.Food

local FoodCombatController = {}



function FoodCombatController:Init(Core)
	self.CurrentFood = nil -- The food the player is currently holding/using

	--modules--
	self.ClientDataController = Core:Get("ClientDataController")
	self.ProjectileController = Core:Get("ProjectileController")
	self.TrajectoryBeam = Core:Get("TrajectoryBeam")
	self.CameraController = Core:Get("CameraController")

	--variables
	self.UltimateActivated = false
	self.CanUltimate = false
	self.CurrentEnergy = 0 -- on the server after using a move that costs energy, use the remote to update this value in order to make gameplay smoother, so the client doesn't rely on the server-sided check
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
		
	 --[[if not self.FoodModules[self.CurrentFood] then
			  if FoodModuleFolder:FindFirstChild(self.CurrentFood.."Client") then
				self.FoodModules[self.CurrentFood] = require(FoodModuleFolder[self.CurrentFood.."Client"])
	 
			  print(self.FoodModules)
			  else
				 warn("no food module found for " .. self.CurrentFood)
			  end
			end]]
	end)

	for _, module in FoodModuleFolder:GetChildren() do
		local Name = string.gsub(module.Name, "Client", "")
		self.FoodModules[Name] = require(module)
	end
end

function FoodCombatController:GetFoodModule(FoodName : string)
	if self.FoodModules[FoodName] then
		return self.FoodModules[FoodName]
	else
		warn("food client module not found for " .. FoodName)
	end
end

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
				self:Fire()
			elseif inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
				self.CameraController:AimZoom()
				self:StartAim()
			elseif inputObject.KeyCode == Enum.KeyCode.E then
				self:ActivateUltimate(LocalPlayer)
			end
		elseif inputState == Enum.UserInputState.End then
			if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
				self.CameraController:StopAim()
			end
		end
	end

	CAS:BindAction(CombatAction, handleProjectile, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.KeyCode.E)
	


	--setup replication--

	self:StartReplication()
end

function FoodCombatController:StartAim()
   local FoodModule = self.FoodModules[self.CurrentFood]
   local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")


	if self.FoodModules[self.CurrentFood].Aim then
		self.FoodModules[self.CurrentFood]:Aim()
		return
	end

	self.TrajectoryBeam:Enable(function()
		return {
			Origin = HRP.Position,
         Velocity = ((Mouse.Hit.Position - HRP.Position).Unit * FoodModule.Config.Projectile.Speed) + (FoodModule.Config.Projectile.InitUpwardVelocity or Vector3.zero),
         Gravity = self.FoodModules[self.CurrentFood].Config.Projectile.Acceleration,
        RaycastParams =  self.ProjectileController.RaycastParams,
		}
	end)
end

function FoodCombatController:StopAim()
	if self.FoodModules[self.CurrentFood].StopAim then
		self.FoodModules[self.CurrentFood]:StopAim()
		return
	end
end


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
		return
	end

	

	
	local Projectile = self.ProjectileController:FireProjectile(FoodModels[self.CurrentFood]:Clone(), {
		Owner = LocalPlayer,
		RaycastParams = self.ProjectileController.RaycastParams,
		Origin = LocalPlayer.Character.HumanoidRootPart.Position,
		Velocity = (Mouse.Hit.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * ProjectileConfig.Speed + ProjectileConfig.InitUpwardVelocity,
		Acceleration = ProjectileConfig.Acceleration,
		MaxBounces = ProjectileConfig.MaxBounces,
	})

	Projectile.OnHit:Connect(function(sender, data)
		print("on hit from the food combat")
		if FoodModule.OnHit then
			FoodModule:OnHit(sender, data)
		end
	end)
end


function FoodCombatController:OnFireReplicated(player, data)
	local AttackerFood = data.Combat.FoodName
	local FoodClientModule = self.FoodModules[AttackerFood]
	FoodClientModule:OnFireReplicated(player, data)	
end

function FoodCombatController:OnHitReplicated(player, data)
	local AttackerFood = data.Combat.FoodName
	local FoodClientModule = self.FoodModules[AttackerFood]
	FoodClientModule:OnHitReplicated(player, data)	
end

function FoodCombatController:HandleSpecialAction(action : string, data)
	local FoodClientModule = self.FoodModules[data.Combat.FoodName]
	FoodClientModule:HandleAction(action, data) 
end


function FoodCombatController:OnHit(player, data)
	local AttackerFood = data.Combat.FoodName
	local FoodClientModule = self.FoodModules[AttackerFood]
	FoodClientModule:OnHit(player,data)
end

function FoodCombatController:ActivateUltimate() 
	local CanActivateUlt = self.CombatEvent:Invoke(10,	"ActivateUltimate")

	print(CanActivateUlt)
	if CanActivateUlt then
		self.UltimateActivated = true
		print("ultimate activation success")
		--insert script if any food has custom usage logic
	end
end

function FoodCombatController:StartReplication()
	self.CombatEvent:Connect(function(action, data)
		if action == "Fire" then
			self:OnFireReplicated(data)
		elseif action == "Hit" then
			self:OnHitReplicated(data)
		
		elseif action == "DeactivateUltimate" then
			print("ultimate deactivated from client")
			self.UltimateActivated = false
		elseif action == "UpdateEnergy" then
			self.CurrentEnergy = data.Energy
			print("energy replicated to client: " .. data.Energy)
			self.EnergyChanged:Fire(data)

		elseif action == "DamageDealt" then --received by a  player who did some damage
			--use to:  
				-- Display damage numbers
				-- Activate Hitmarker
				print("handling damage dealt effects")
				self.DamageDealt:Fire(data)

		elseif action == "Damaged" then --received by a player who got hit
			--use to:
				--activate hit marker
			self.DamageReceived:Fire(data)
		else
			print(action, data)
			self:HandleSpecialAction(action, data)
			--pass up to custom action management
		end
	end)
end

return FoodCombatController
