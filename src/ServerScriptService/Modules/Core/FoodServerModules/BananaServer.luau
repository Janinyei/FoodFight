--handles the chicken npcs, replication, etc
--this code might have a memory leak lol

local BananaServer = {}

--Services--
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Modules
--Imports--
local UtilFunctions = require(ReplicatedStorage.Modules.Utils.Functions)
local Hitbox = require(Modules.Utils.Hitbox)
--
function BananaServer:Init(Core)
	self.ProjectileManager = Core:Get("ProjectileManager")
	self.Config = require(ReplicatedStorage.Modules.Info.FoodCombatConfigs.EggConfig)
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")
	self.FoodCombatManager = Core:Get("FoodCombatManager")
	self.EnergyManager = Core:Get("EnergyManager")
	self.StatusEffectManager = Core:Get("StatusEffectManager")
end

function BananaServer:OnFire(player, data)
	if data.Combat.isUltimate then
		self.EnergyManager:Drain(player, 100)
	end
end

function BananaServer:OnHit(player, data)
	local character = UtilFunctions.FindCharacter(data.Projectile.HitResult.Instance)
	if character then
        --simply ragdoll whoever it hits
		return
	end

	if not data.Combat.Ultimate then
		return
	end

	--make a downwards ray to spawn on ground
	local RayOrigin = data.Projectile.HitResult.Position + data.Projectile.HitResult.Normal
	local RayDir = Vector3.yAxis * -4
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = { workspace.VisualEffectsCache }
	local PeelRay = workspace:Raycast(RayOrigin, RayDir)
	
	if PeelRay then
		local BananaPeel = ReplicatedStorage.Assets.Food.Banana.BananaPeel:Clone()
		BananaPeel.Parent = workspace.VisualEffectsCache
		BananaPeel.CanQuery = false
		BananaPeel.CanCollide = false
		BananaPeel.Anchored = true
		BananaPeel.Position = PeelRay.Position + Vector3.yAxis * BananaPeel.Size.Y / 2
        

		Debris:AddItem(BananaPeel, 20)

        local BananaPeelHitbox =  Hitbox.new()
        BananaPeelHitbox.DetectionMode = "Region"
      --  BananaPeelHitbox:SetOwner(player.Character)
        BananaPeelHitbox.Size = Vector3.one * 5
        BananaPeelHitbox.CFrame = CFrame.new(data.Projectile.HitResult.Position + Vector3.yAxis * BananaPeelHitbox.Size.Y/2)
         BananaPeelHitbox.DebugMode = true


        BananaPeelHitbox:Start()


        BananaPeelHitbox.OnHit = function(hitData)
            print(hitData.Model)  
            --apply ragdoll status effect

            local hitCharacter = hitData.Model
			local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
			if hitPlayer then
				self.StatusEffectManager:ApplyEffect(hitPlayer, "Ragdoll")
			end
			
            BananaPeelHitbox:Destroy()
        end
	end
end

return BananaServer
