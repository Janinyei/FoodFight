--Purpose: To help simulate the client-sided projectile physics
--Note: most essential module to the gameplay. Be mindful of any changes
--janin 10/22/25

local ProjectileController = {}

--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CAS = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

--Modules--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils

--Imports--
local Projectile = require(script.Projectile)
local Highlights = require(Utils.Highlights)
local DamageNumbers = require(Utils.DamageNumbers)
--Data--
local FoodIndex = require(Modules.Info.FoodProjectileIndex)

--Variables--
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local FoodModels = ReplicatedStorage.Assets.FoodModels
local LocalProjectiles = {}
local ReplicatedProjectiles = {}

local DebugInstanceFolder = Instance.new("Folder")
DebugInstanceFolder.Parent = workspace
DebugInstanceFolder.Name = "DebugInstances"

--Projectile Controller Methods
function ProjectileController:Init(Core)
	self.RaycastParams = RaycastParams.new()
	self.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.Blacklist = { DebugInstanceFolder }
	self.RaycastParams.FilterDescendantsInstances = self.Blacklist
	self.ProjectileCooldowns = {}

	--Core modules/events
	self.Core = Core
	self.ProjectileEvent = Core:Get("SharedRemotes"):GetEvent("ProjectileEvent")
	self.ClientDataController = Core:Get("ClientDataController")
	self.VFXController = Core:Get("VFXController")
	self.FoodEffectsController = Core:Get("FoodEffectsController")
	self.TrajectoryBeam = Core:Get("TrajectoryBeam")

	-- Add local character to blacklist if it exists
	if LocalPlayer.Character then
		table.insert(self.Blacklist, LocalPlayer.Character)
		self.RaycastParams.FilterDescendantsInstances = self.Blacklist
	end

	-- Update blacklist when character spawns
	LocalPlayer.CharacterAdded:Connect(function(character)
		-- Remove old character from blacklist
		for i, v in ipairs(self.Blacklist) do
			if typeof(v) == "Instance" and v:IsDescendantOf(Players) then
				table.remove(self.Blacklist, i)
				break
			end
		end
		-- Add new character
		table.insert(self.Blacklist, character)
		self.RaycastParams.FilterDescendantsInstances = self.Blacklist
	end)
end

function ProjectileController:Start()
	--whenever someone clicks, create and fire a projectile
	local fireAction = "FireProjectile"

	local function fireProj(inputObject, inputState)
		if inputState == Enum.UserInputState.Begin then
			--aiming
			--use trajectory beam to assist players in aiming
			local Inventory = self.ClientDataController:GetInventory()
			local EquippedFood = Inventory.Equipped.Food or nil
			self:AttemptAim(EquippedFood)

		elseif inputState == Enum.UserInputState.End then
			--firing
			local Inventory = self.ClientDataController:GetInventory()
			local EquippedFood = Inventory.Equipped.Food or nil
			self:AttemptFire(EquippedFood)
		end
	end

	CAS:BindAction(fireAction, fireProj, false, Enum.UserInputType.MouseButton1)
	--setup replication event here to receive visual effects and such
	self:StartReplicationListener()
end

--repetitive code very nice 😐 (will refactor in 10 years)
function ProjectileController:AttemptAim(FoodName : string)
	if LocalPlayer.Character == nil then
		return
	end
	
	local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not HRP then
		return
	end

	local function getTrajectoryData() --necessary for frame-by-frame update
		local foodData = FoodIndex[FoodName]
	

		local Origin = HRP.Position + HRP.CFrame.LookVector * 5
		local Direction = (Mouse.Hit.Position - Origin).Unit
		local Speed = foodData.Speed or 150
		local Velocity = Direction * Speed

		return {
			Origin = Origin,
			Velocity = Velocity,
			Gravity = foodData.Gravity or Vector3.new(0,-30,0),
			RaycastParams = self.RaycastParams
		}
		
	end
	


	self.TrajectoryBeam:Enable(getTrajectoryData)
	
	
end

function ProjectileController:GenerateProjectileId()
	return LocalPlayer.UserId .. "_" .. HttpService:GenerateGUID(false)
end

function ProjectileController:AttemptFire(FoodName: string)
	--check character instances
	if LocalPlayer.Character == nil then
		return
	end

	local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not HRP then
		return
	end

	--check cooldowns
	local currentTime = tick()
	local foodData = FoodIndex[FoodName]
	if not foodData then
		warn("Food not found:", FoodName)
		return
	end

	local cooldown = foodData.Cooldown or 1
	if self.ProjectileCooldowns[FoodName] and currentTime - self.ProjectileCooldowns[FoodName] < cooldown then
		return
	end

	--define launch parameters
	local Origin = HRP.Position + HRP.CFrame.LookVector * 5
	local Direction = (Mouse.Hit.Position - Origin).Unit
	local Speed = foodData.Speed or 150
	local Velocity = Direction * Speed

	-- Generate unique ID
	local ProjectileId = self:GenerateProjectileId()

	--create & fire projectile
	local ProjectileData = {
		Id = ProjectileId,
		Origin = Origin,
		Velocity = Velocity,
		Owner = LocalPlayer,
		Restitution = foodData.Restitution,
		Acceleration = foodData.Gravity,
		MaxBounces = foodData.MaxBounces,
		MaxDistance = 1000,
		RaycastParams = self.RaycastParams,
		Lifetime = 30,
		Update = foodData.Update,
	}

	-- Create food model
	local FoodModel = FoodModels[FoodName]:Clone()
	FoodModel.Parent = workspace

	-- Add to blacklist
	table.insert(self.Blacklist, FoodModel)
	self.RaycastParams.FilterDescendantsInstances = self.Blacklist

	-- Create projectile
	local NewProj = Projectile.new(ProjectileData)
	NewProj:LoadModel(FoodModel)

	-- Store in local projectiles
	LocalProjectiles[ProjectileId] = NewProj

	-- Fire projectile
	NewProj:Fire()

	NewProj.OnFire:Connect(function()
		print("handle visual effects")
	end)

	-- Send to server for replication
	self.ProjectileEvent:Fire(true, "Fire", {
		Id = ProjectileId,
		Owner = LocalPlayer,
		Origin = Origin,
		Direction = Direction,
		Velocity = Velocity,
		FoodName = FoodName,
		Timestamp = tick(),
	})

	local SpecialActivated = true
	-- Setup hit connection
	NewProj.OnHit:Connect(function(hitResult)
		-- Check if we hit a player
		local hitInstance = hitResult.Instance
		local humanoid = hitInstance.Parent:FindFirstChildOfClass("Humanoid")

	
		self.FoodEffectsController:OnHit({
			Name = FoodName,
			HitResult = { --have to create a table instead of just passing in regular raycastresult objects because roblox doesn't replicate RaycastResults fsr
				Instance = hitResult.Instance,
				Position = hitResult.Position,
				Normal = hitResult.Normal,
			}
		})

		--Check if the projectile hits a player or not
		if humanoid and hitInstance.Parent ~= LocalPlayer.Character then
			local hitCharacter = hitInstance.Parent
			local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)

			if not hitPlayer and hitCharacter:IsA("Model") then
				hitPlayer = hitCharacter
			end

			if hitCharacter and hitCharacter:IsA("Model") then
				Highlights:HighlightModel(hitCharacter)
			end

			-- Send hit validation to server
			self.ProjectileEvent:Fire(true, "Hit", {
				ProjectileId = ProjectileId,
				HitPlayer = hitPlayer,
				HitPosition = hitResult.Position,
				HitPart = hitInstance.Name,
				Velocity = NewProj.Velocity,
				Timestamp = tick(),
			})
		else
			-- Hit environment
			self.ProjectileEvent:Fire(true, "Hit", {
				ProjectileId = ProjectileId,
				HitPosition = hitResult.Position,
				HitNormal = hitResult.Normal,
				Velocity = NewProj.Velocity,
				Timestamp = tick(),
			})
		end
	end)

	-- Setup cleanup
	NewProj.OnDestroyed:Connect(function()
		LocalProjectiles[ProjectileId] = nil
		-- Remove from blacklist
		for i, v in ipairs(self.Blacklist) do
			if v == FoodModel then
				table.remove(self.Blacklist, i)
				break
			end
		end
		self.RaycastParams.FilterDescendantsInstances = self.Blacklist
	end)
	-- Set cooldown
	self.ProjectileCooldowns[FoodName] = currentTime
end

function ProjectileController:StartReplicationListener()
	self.ProjectileEvent:Connect(function(action, ProjData)
		print(action, ProjData)
		if action == "Fire" then
			-- Don't replicate our own projectiles

			if ProjData.Owner == LocalPlayer then
				return
			end

			-- Validate owner has character
			local OwnerCharacter = ProjData.Owner.Character
			if not OwnerCharacter then
				return
			end

			local OwnerHRP = OwnerCharacter:FindFirstChild("HumanoidRootPart")
			if not OwnerHRP then
				return
			end

			-- Get food data
			local foodData = FoodIndex[ProjData.FoodName] or {}

			-- Create replicated projectile
			local ReplicatedProjectileData = {
				Id = ProjData.Id,
				Origin = ProjData.Origin,
				Velocity = ProjData.Velocity,
				Owner = ProjData.Owner,
				Restitution = foodData.Restitution,
				Acceleration = foodData.Gravity,
				MaxBounces = foodData.MaxBounces,
				MaxDistance = 1000,
				RaycastParams = self.RaycastParams,
				Lifetime = 30,
				IsReplicated = true,
				Update = foodData.Update,
			}

			-- Create replicated projectile
			local ReplicatedProjectile = Projectile.new(ReplicatedProjectileData)
			ReplicatedProjectiles[ProjData.Id] = ReplicatedProjectile

			-- Create and load model
			local FoodModel = FoodModels[ProjData.FoodName]:Clone()
			FoodModel.Parent = workspace

			-- Add to blacklist
			table.insert(self.Blacklist, FoodModel)
			self.RaycastParams.FilterDescendantsInstances = self.Blacklist

			ReplicatedProjectile:LoadModel(FoodModel)
			ReplicatedProjectile:Fire()

			ReplicatedProjectile.OnHit:Connect(function(hitResult)
				local hitInstance = hitResult.Instance
				local humanoid = hitInstance.Parent:FindFirstChildOfClass("Humanoid")

				if humanoid and hitInstance.Parent and hitInstance.Parent:IsA("Model") then
					local hitCharacter = hitInstance.Parent
					Highlights:HighlightModel(hitCharacter)
				end

				self.VFXController:PlayVFX({
					Position = hitResult.Position,
					Normal = hitResult.Normal,
					FoodName = ProjData.FoodName,
				})
			end)

			-- Setup cleanup
			ReplicatedProjectile.OnDestroyed:Connect(function()
				ReplicatedProjectiles[ProjData.Id] = nil
				-- Remove from blacklist
				for i, v in ipairs(self.Blacklist) do
					if v == FoodModel then
						table.remove(self.Blacklist, i)
						break
					end
				end
				self.RaycastParams.FilterDescendantsInstances = self.Blacklist
			end)
		elseif action == "Hit" then
			print("HIT", ProjData)
			-- Handle hit confirmation from server
			local ProjectileId = ProjData.ProjectileId

			-- Destroy the projectile (server confirmed hit)
			if ProjData.Destroyed then
				if LocalProjectiles[ProjectileId] then
					LocalProjectiles[ProjectileId]:Destroy()
					LocalProjectiles[ProjectileId] = nil
				elseif ReplicatedProjectiles[ProjectileId] then
					ReplicatedProjectiles[ProjectileId]:Destroy()
					ReplicatedProjectiles[ProjectileId] = nil
				end
			end
		elseif action == "Bounce" then
			-- Update replicated projectile bounce
			local ProjectileId = ProjData.Id
			if ReplicatedProjectiles[ProjectileId] then
				local projectile = ReplicatedProjectiles[ProjectileId]
				projectile.Velocity = ProjData.Velocity
				projectile.Position = ProjData.Position
				projectile.BounceCount = ProjData.BounceCount or projectile.BounceCount
			end
		elseif action == "Destroyed" then
			-- Clean up destroyed projectile
			local ProjectileId = ProjData.ProjectileId
			if LocalProjectiles[ProjectileId] then
				LocalProjectiles[ProjectileId]:Destroy()
				LocalProjectiles[ProjectileId] = nil
			elseif ReplicatedProjectiles[ProjectileId] then
				ReplicatedProjectiles[ProjectileId]:Destroy()
				ReplicatedProjectiles[ProjectileId] = nil
			end
		elseif action == "Damage" then
			local target = ProjData.Target
			local damage = ProjData.Damage
			local attacker = ProjData.Attacker
			local isKill = ProjData.IsKill

			print("DAMAGE", ProjData)

			if not target then
				return
			end

			local targetCharacter
			local targetName

			if target:IsA("Player") then
				targetCharacter = target.Character
				if not targetCharacter then
					return
				end
				targetName = target.DisplayName or target.Name
			elseif target:IsA("Model") then
				-- It's an NPC/model, use the model directly
				if not target.Parent then
					return
				end
				targetCharacter = target
				targetName = target.Name
			else
				-- Invalid target
				return
			end
			
			DamageNumbers:ShowDamage(targetCharacter, damage)
			-- If killed, show kill message and exp
			if isKill and attacker == LocalPlayer then
				--Core:Get("KillMessage"):ShowKill(targetName, 100, 100)
				--FloatingXP:ShowXP(100)
			end
		end
	end)
end

return ProjectileController
