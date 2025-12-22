--Purpose: Handles projectile replication and validation
--librium 10/26/25

--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--Modules--
local Modules = ReplicatedStorage.Modules
--Events

--Constants
local MAX_PROJECTILES_PER_PLAYER = 500
local POSITION_TOLERANCE = 20
local HIT_VALIDATION_DISTANCE = 30
local PROJECTILE_TIMEOUT = 30

local ProjectileManager = {}

function ProjectileManager:Init(Core)
	self.ActiveProjectiles = {}
	self.PlayerProjectileCount = {}
	self.PlayerLastFireTime = {}
	self.PlayerCooldowns = {}
	self.ProjectileEvent = Core:Get("SharedRemotes"):GetEvent("ProjectileEvent")

	self.ProjectileEvent:Connect(function(player, action, data)
		-- Validate player
		if not player or not player.Parent then
			return
		end

		if action == "Fire" then
			self:HandleFireProjectile(player, data)
		elseif action == "Hit" then
			self:HandleProjectileHit(player, data)
		elseif action == "Bounce" then
			self:HandleProjectileBounce(player, data)
		end
	end)

	-- Clean up when players leave
	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerData(player)
	end)

	-- Start cleanup loop
	self:StartCleanupLoop()
end

function ProjectileManager:HandleFireProjectile(player, data)
	-- Validate fire request
	local isValid, reason = self:ValidateFireRequest(player, data)
	if not isValid then
		warn("Invalid projectile from", player.Name, "Reason:", reason)
		return
	end

	-- Store projectile
	self.ActiveProjectiles[data.Id] = {
		Id = data.Id,
		Owner = player,
		FoodName = data.FoodName,
		Origin = data.Origin,
		Direction = data.Direction,
		Velocity = data.Velocity,
		StartTime = tick(),
		HitPlayers = {},
		BounceCount = 0,
	}

	-- Update tracking
	self.PlayerProjectileCount[player] = (self.PlayerProjectileCount[player] or 0) + 1
	self.PlayerLastFireTime[player] = tick()

	if not self.PlayerCooldowns[player] then
		self.PlayerCooldowns[player] = {}
	end
	self.PlayerCooldowns[player][data.FoodName] = tick()

	-- Replicate to ALL clients
--[[self.ProjectileEvent:FireExcept(true, { player }, "Fire", {
        Id = data.Id,
        Owner = player,
        FoodName = data.FoodName,
        Origin = data.Origin,
        Direction = data.Direction,
        Velocity = data.Velocity,
        Timestamp = tick(),
    })]]

	
end

function ProjectileManager:ValidateFireRequest(player, data)
	-- Check character
	local character = player.Character
	if not character then
		return false, "No character"
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return false, "No HumanoidRootPart"
	end

	-- Check projectile count
	local currentCount = self.PlayerProjectileCount[player] or 0
	if currentCount >= MAX_PROJECTILES_PER_PLAYER then
		return false, "Too many projectiles"
	end



	-- Validate origin
	local distance = (data.Origin - humanoidRootPart.Position).Magnitude
	if distance > POSITION_TOLERANCE then
		return false, "Origin too far"
	end

	return true, "Valid"
end

function ProjectileManager:HandleProjectileHit(player, data)
	-- Validate hit
	local projectile = self.ActiveProjectiles[data.ProjectileId]
	if not projectile then
		return
	end

	if projectile.Owner ~= player then
		warn("Player doesn't own projectile")
		return
	end

	local shouldDestroy = false

	-- Handle player/NPC hit
	if data.HitPlayer then
		-- Check if HitPlayer is a Player or a Model
		local targetCharacter
		if data.HitPlayer:IsA("Player") then
			if not data.HitPlayer.Parent then
				return
			end
			targetCharacter = data.HitPlayer.Character
			if not targetCharacter then
				return
			end
			
			if data.HitPlayer == player then
				return
			end
		elseif data.HitPlayer:IsA("Model") then
			-- It's an NPC/model, use the model directly
			if not data.HitPlayer.Parent then
				return
			end
			targetCharacter = data.HitPlayer
		else
			-- Invalid hit target
			return
		end

		-- Check if already hit
		if projectile.HitPlayers[data.HitPlayer] then
			return
		end


	else
		-- Environment hit - check bounces
		if projectile.BounceCount >= (foodData.MaxBounces or 0) then
			shouldDestroy = true
		else
			projectile.BounceCount = projectile.BounceCount + 1
		end
	end

	
	-- Remove if destroyed
	if shouldDestroy then
		self:RemoveProjectile(projectile.Id)
	end
end

function ProjectileManager:HandleProjectileBounce(player, data)
	local projectile = self.ActiveProjectiles[data.Id]
	if not projectile or projectile.Owner ~= player then
		return
	end

	projectile.BounceCount = data.BounceCount or projectile.BounceCount + 1

	-- Replicate to other clients
	for _, client in pairs(Players:GetPlayers()) do
		if client ~= player then
			self.ProjectileEvent:Fire(client, "Bounce", data)
		end
	end
end

function ProjectileManager:RemoveProjectile(projectileId)
	local projectile = self.ActiveProjectiles[projectileId]
	if not projectile then
		return
	end

	local owner = projectile.Owner
	if owner and self.PlayerProjectileCount[owner] then
		self.PlayerProjectileCount[owner] = math.max(0, self.PlayerProjectileCount[owner] - 1)
	end

	self.ActiveProjectiles[projectileId] = nil
end

function ProjectileManager:CleanupPlayerData(player)
	-- Remove all projectiles
	for id, projectile in pairs(self.ActiveProjectiles) do
		if projectile.Owner == player then
			self:RemoveProjectile(id)
			-- Notify clients
			for _, client in pairs(Players:GetPlayers()) do
				if client ~= player then
					self.ProjectileEvent:Fire(client, "Destroyed", {
						ProjectileId = id,
					})
				end
			end
		end
	end

	self.PlayerProjectileCount[player] = nil
	self.PlayerLastFireTime[player] = nil
	self.PlayerCooldowns[player] = nil
end

function ProjectileManager:StartCleanupLoop()
	task.spawn(function()
		while true do
			task.wait(5)

			local currentTime = tick()
			for id, projectile in pairs(self.ActiveProjectiles) do
				if currentTime - projectile.StartTime > PROJECTILE_TIMEOUT then
					self:RemoveProjectile(id)

					self.ProjectileEvent:Fires(true, "Destroyed", {
						ProjectileId = id,
					})
				end
			end
		end
	end)
end

return ProjectileManager
