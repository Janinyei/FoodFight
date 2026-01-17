--Purpose: To help simulate the client-sided projectile physics
--note: this module doesn't actually have the physics in it. that would be the projectile class.
--Note: most essential module to the gameplay. Be mindful of any changes
--janin 10/22/25

local ProjectileController = {}

--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

--Modules--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils

--Imports--
local Projectile = require(Utils.Projectile)
local DamageHighlights = require(Utils.DamageHighlights)
local Signal = require(Utils.Signal)
--Data--

--Variables--
local LocalPlayer = Players.LocalPlayer
local LocalProjectiles = {}
local ReplicatedProjectiles = {}

local DebugInstanceFolder = Instance.new("Folder")
DebugInstanceFolder.Parent = workspace
DebugInstanceFolder.Name = "DebugInstances"

--Projectile Controller Methods
function ProjectileController:Init(Core)
	self.RaycastParams = RaycastParams.new()
	self.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.AlwaysExcludedInstances = { DebugInstanceFolder, workspace.VisualEffectsCache }
	self.Blacklist = { DebugInstanceFolder, workspace.VisualEffectsCache }
	self.RaycastParams.FilterDescendantsInstances = self.Blacklist
	self.DefaultHitRadius = 0.85

	--Core modules/events
	self.Core = Core
	self.ProjectileEvent = Core:Get("SharedRemotes"):GetEvent("ProjectileEvent")
	self.TrailsController = Core:Get("TrailsController")

	-- Add local character to blacklist if it exists
	if LocalPlayer.Character then
		table.insert(self.Blacklist, LocalPlayer.Character)
		self.RaycastParams.FilterDescendantsInstances = self.Blacklist
	end

	-- Update blacklist when character spawns
	LocalPlayer.CharacterAdded:Connect(function(character)
		-- Remove old character from blacklist
		-- Add new character
		table.insert(self.Blacklist, character)
		self.RaycastParams.FilterDescendantsInstances = self.Blacklist
	end)
end

function ProjectileController:Start()
	-- Setup replication listener to respond to server events (Destroyed, Bounce, etc.)
	self.ProjectileEvent:Connect(function(action, ProjData)
		if action == "Destroyed" then
			local ProjectileId = ProjData.ProjectileId
			if LocalProjectiles[ProjectileId] then
				LocalProjectiles[ProjectileId]:Destroy()
				LocalProjectiles[ProjectileId] = nil
			elseif ReplicatedProjectiles[ProjectileId] then
				ReplicatedProjectiles[ProjectileId]:Destroy()
				ReplicatedProjectiles[ProjectileId] = nil
			end
		elseif action == "Bounce" then
			local ProjectileId = ProjData.Id
			if ReplicatedProjectiles[ProjectileId] then
				local projectile = ReplicatedProjectiles[ProjectileId]
				projectile.Velocity = ProjData.Velocity
				projectile.Position = ProjData.Position
				projectile.BounceCount = ProjData.BounceCount or projectile.BounceCount
			end
		end
	end)
end

--I might refactor this to  CreateProjectile instead
--then I can fire the projectile from the foodcombat controller
function ProjectileController:FireProjectile(Obj: Model | BasePart, ProjectileData)

	if not ProjectileData then
		warn("cannot shoot projectile with no data")
		return
	end
	
	if ProjectileData.HitRadius == nil then
		ProjectileData.HitRadius = self.DefaultHitRadius
	end

	-- Add to blacklist
	table.insert(self.Blacklist, Obj)
	self.RaycastParams.FilterDescendantsInstances = self.Blacklist

	-- Create projectile
	local NewProj = Projectile.new(ProjectileData)
	NewProj:LoadModel(Obj)

	-- Store in  projectiles

	print(ProjectileData)
	if NewProj.Owner ~= LocalPlayer then --replicated projectile
		ReplicatedProjectiles[ProjectileData.Id] = NewProj
		--sets up different raycast params to avoid conflicts
		local RayParams = RaycastParams.new()
		local filter = { DebugInstanceFolder, workspace.VisualEffectsCache, Obj }
		if NewProj.Owner.Character then
			table.insert(filter, NewProj.Owner.Character)
		end
		RayParams.FilterDescendantsInstances = filter
		RayParams.FilterType = Enum.RaycastFilterType.Exclude
		NewProj.RaycastParams = RayParams
	else
		
		LocalProjectiles[NewProj.Id] = NewProj
	end

	-- Fire projectile
	NewProj:Fire()

	NewProj.OnDestroyed:Connect(function()
		LocalProjectiles[NewProj.Id] = nil
		ReplicatedProjectiles[NewProj.Id] = nil
	end)

	self.TrailsController:LoadTrail(NewProj.Model)

	return NewProj
end


function ProjectileController:GenerateProjectileId(owner: Player)
	-- Generate unique ID
	return owner.UserId .. "_" .. HttpService:GenerateGUID(false)
end

function ProjectileController:GetProjectile(Id)
	if ReplicatedProjectiles[Id] then
		print("found in replicated projectiles")
		return ReplicatedProjectiles[Id]
	elseif LocalProjectiles[Id] then
		return LocalProjectiles[Id]
	end
end

--[[function ProjectileController:StartReplicationListener()
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
					DamageHighlights:HighlightModel(hitCharacter)
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

			self.OnDamaged:Fire(targetCharacter, damage, isKill)
			-- If killed, show kill message and exp
			if isKill and attacker == LocalPlayer then
				--Core:Get("KillMessage"):ShowKill(targetName, 100, 100)
				--FloatingXP:ShowXP(100)
			end
		end
	end)
end]]
--this is obsolete now


return ProjectileController
