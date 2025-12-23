--purpose: food module for combat
--tzu 12/23/25

local GrapesClient = {}

--Services--
local Debris = game.Debris
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--Modules--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils
--Imports--
local Functions = require(Utils.Functions)

--Variables--
local LocalPlayer = Players.LocalPlayer
local FoodModels = ReplicatedStorage.Assets.FoodModels
local Mouse = LocalPlayer:GetMouse()

--helpers--
local function CreateGrapeModel()
	local Grapes = FoodModels:FindFirstChild("GrapeModel")
	if Grapes and Grapes:FindFirstChild("Balls") then
		local balls = Grapes.Balls:GetChildren()
		if #balls > 0 then
			local ball = balls[math.random(1, #balls)]:Clone()
			ball.CanCollide = false
			ball.CanQuery = false
			return ball
		end
	end
    return nil
end

function GrapesClient:Init(Core)
	self.ProjectileController = Core:Get("ProjectileController")
	self.Config = require(ReplicatedStorage.Modules.Info.FoodCombatConfigs.GrapesConfig)
	self.VFXController = Core:Get("VFXController")
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")
	self.ClientDataController = Core:Get("ClientDataController")
	self.IsUltimateActive = false
	self.RotationAngle = 0
	self.BaseWeldC0 = nil
	self.LastUltFireTick = 0
	self.CurrentUltScale = 4
	self.CurrentUltRotSpeed = 0
end

function GrapesClient:GetHeldGrapes()
	local Char = LocalPlayer.Character
	if not Char then
		return nil
	end
	return Char:FindFirstChild("Grapes", true)
end

function GrapesClient:Equip()
	local Char = LocalPlayer.Character
	if not Char then return end
		
	local Existing = self:GetHeldGrapes()
	if Existing then return Existing end
	
	local GrapeModel = FoodModels:FindFirstChild("GrapeModel")
	if not GrapeModel then 
		return 
	end
	
	local Clone = GrapeModel:Clone()
	Clone.Name = "Grapes"
	Clone.Parent = Char
	
	local Hold = Clone:FindFirstChild("Top") or Clone.PrimaryPart
	
	local Weld = Instance.new("Weld")
	Weld.Name = "GrapesWeld"
	Weld.Part0 = Char:FindFirstChild("HumanoidRootPart")
	Weld.Part1 = Hold
	Weld.C0 = CFrame.new(3, 3, 0.5) * CFrame.Angles(0, math.rad(90), math.rad(90))
	Weld.Parent = Hold

	self.BaseWeldC0 = Weld.C0
	return Clone
end

function GrapesClient:PickRandomBall()
	local grapes = self:GetHeldGrapes()
	if not grapes then return nil end
	
	local BallsFolder = grapes:FindFirstChild("Balls")
	if not BallsFolder then return nil end
	
	local balls = BallsFolder:GetChildren()
	if #balls == 0 then return nil end
	
	return balls[math.random(1, #balls)]
end

function GrapesClient:FireNormal()
	local ProjectileConfig = self.Config.Projectile
	local HRP = LocalPlayer.Character.HumanoidRootPart
	local Origin = HRP.Position
	local BaseDirection = (Mouse.Hit.Position - Origin).Unit

	for _ = 1, ProjectileConfig.BurstCount do
		local Spread = ProjectileConfig.Spread
		local ShotDirection = (BaseDirection + Vector3.new(
			math.random(-100, 100) / 100 * Spread,
			math.random(-100, 100) / 100 * Spread,
			math.random(-100, 100) / 100 * Spread
		)).Unit

		local projModel = self:PickRandomBall()
		if projModel then
			projModel = projModel:Clone()
		else
			projModel = CreateGrapeModel()
		end
		
		if not projModel then continue end

		projModel.CanCollide = false
		projModel.CanQuery = false

		local FireData = {
			Sender = LocalPlayer,
			Combat = { FoodName = "Grapes", Ultimate = false },
			Projectile = {
				Owner = LocalPlayer,
				Origin = Origin,
				Velocity = (ShotDirection * ProjectileConfig.Speed) + (ProjectileConfig.InitUpwardVelocity or Vector3.zero),
				Acceleration = ProjectileConfig.Acceleration,
				MaxBounces = ProjectileConfig.MaxBounces,
				RaycastParams = self.ProjectileController.RaycastParams,
				MaxHits = ProjectileConfig.MaxHits,
				DestroyOnHit = ProjectileConfig.DestroyOnHit
			}
		}

		local Proj = self.ProjectileController:FireProjectile(projModel, FireData.Projectile)
		FireData.Projectile.Id = Proj.Id
		FireData.Projectile.RaycastParams = nil
		self.CombatEvent:Fire(true, "Fire", FireData)

		Proj.OnHit:Connect(function(HitResult)
			local hitData = {
				Sender = LocalPlayer,
				Combat = { FoodName = "Grapes", Ultimate = false },
				Projectile = {
					Id = Proj.Id,
					HitResult = { Instance = HitResult.Instance, Position = HitResult.Position, Normal = HitResult.Normal }
				}
			}
			self.CombatEvent:Fire(true, "Hit", hitData)
		end)
	end
end

function GrapesClient:FireUltimate()
	local UltConfig = self.Config.Ultimate
	local ProjConfig = self.Config.Projectile
	local HRP = LocalPlayer.Character.HumanoidRootPart

	self:Equip()

	task.spawn(function()
		for _ = 1, UltConfig.GatlingCount do
			if not LocalPlayer.Character or not HRP or not self.IsUltimateActive then
				break
			end
			self.LastUltFireTick = tick()

			local Origin = HRP.Position
			local BaseDirection = (Mouse.Hit.Position - Origin).Unit
			local Spread = UltConfig.Spread

			local ShotDirection = (BaseDirection + Vector3.new(
				math.random(-100, 100) / 100 * Spread,
				math.random(-100, 100) / 100 * Spread,
				math.random(-100, 100) / 100 * Spread
			)).Unit

			local ball = self:PickRandomBall()
			local GrapeProjectileModel
			local StartOrigin = Origin

			if ball then
				GrapeProjectileModel = ball:Clone()
				GrapeProjectileModel.Parent = workspace
				GrapeProjectileModel.CFrame = ball.CFrame
				GrapeProjectileModel.CanCollide = false
				GrapeProjectileModel.Anchored = true
				StartOrigin = ball.CFrame.Position
			else
				GrapeProjectileModel = CreateGrapeModel()
			end

			local FireData = {
				Sender = LocalPlayer,
				Combat = { FoodName = "Grapes", Ultimate = true },
				Projectile = {
					Owner = LocalPlayer,
					Origin = StartOrigin,
					Velocity = (ShotDirection * ProjConfig.Speed) + (ProjConfig.InitUpwardVelocity or Vector3.zero),
					Acceleration = ProjConfig.Acceleration,
					MaxBounces = 1,
					RaycastParams = self.ProjectileController.RaycastParams,
					MaxHits = 1,
					DestroyOnHit = true,
				},
			}

			local Proj = self.ProjectileController:FireProjectile(GrapeProjectileModel, FireData.Projectile)
			FireData.Projectile.Id = Proj.Id
			FireData.Projectile.RaycastParams = nil
			self.CombatEvent:Fire(true, "Fire", FireData)

			Proj.OnHit:Connect(function(HitResult)
				local hitData = {
					Sender = LocalPlayer,
					Combat = { FoodName = "Grapes", Ultimate = true },
					Projectile = {
						Id = Proj.Id,
						HitResult = {
							Instance = HitResult.Instance,
							Position = HitResult.Position,
							Normal = HitResult.Normal,
						},
					},
				}
				self.CombatEvent:Fire(true, "Hit", hitData)
			end)

			task.wait(UltConfig.FireRate)
		end
	end)
end

function GrapesClient:OnFire() end

function GrapesClient:OnUltimateActivated()
	self.IsUltimateActive = true
	
	local grapes = self:GetHeldGrapes()
	if not grapes then
		grapes = self:Equip()
	end

	if grapes then
		local Top = grapes:FindFirstChild("Top")
		local Weld = Top and Top:FindFirstChild("GrapesWeld")
		
		if not self.RotationConn and Weld then
			self.BaseWeldC0 = self.BaseWeldC0 or Weld.C0
			local baseC0 = self.BaseWeldC0
			local currentAngle = 0
			self.CurrentUltRotSpeed = math.rad(500)
			self.CurrentUltScale = 0

			self.RotationConn = RunService.RenderStepped:Connect(function(dt)
				if not self.IsUltimateActive then return end
				local g = self:GetHeldGrapes()
				if not g then return end

				local shooting = (tick() - self.LastUltFireTick) < 0.2
				local baseScale = 4
				local targetRotSpeed = shooting and math.rad(5000) or math.rad(500)
				local targetScale = shooting and (baseScale * 1.25) or baseScale

				self.CurrentUltRotSpeed = Functions.Lerp(self.CurrentUltRotSpeed, targetRotSpeed, dt * 5)
				self.CurrentUltScale = Functions.Lerp(self.CurrentUltScale, targetScale, dt * 10)
				
				currentAngle += dt * self.CurrentUltRotSpeed
				Weld.C0 = baseC0 * CFrame.Angles(currentAngle, 0, 0)

				g:ScaleTo(self.CurrentUltScale)
			end)
		end
	end
end

function GrapesClient:OnUltimateDeactivated()
	self.IsUltimateActive = false

	local grapes = self:GetHeldGrapes()
	if grapes then
		task.spawn(function()
			local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			local lastTween
			for _, v in ipairs(grapes:GetDescendants()) do
				if v:IsA("BasePart") then
					lastTween = TweenService:Create(v, fadeInfo, { Transparency = 1 })
					lastTween:Play()
				end
			end
			if lastTween then
				lastTween.Completed:Wait()
			end
			grapes:Destroy()
		end)
	end

	self.AnimChains = {}
	if self.RotationConn then
		self.RotationConn:Disconnect()
		self.RotationConn = nil
	end
end

function GrapesClient:Start() end

function GrapesClient:FireReplicated(data)
	self.ProjectileController:FireProjectile(CreateGrapeModel(), data.Projectile)
end

function GrapesClient:OnHit(_, _) end
function GrapesClient:OnHitUltimate(_, _) end
function GrapesClient:OnHitReplicated(_) end

return GrapesClient
