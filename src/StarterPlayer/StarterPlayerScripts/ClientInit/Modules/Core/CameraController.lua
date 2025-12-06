-- CameraController
-- Manages camera behaviors like aiming zoom and is integrated with TrajectoryBeam
-- tzu 12/06/25

local CameraController = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage.Modules
local FoodIndex = require(Modules.Info.FoodProjectileIndex)

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Constants
local AIM_FOV = 50

function CameraController:Init(Core)
	self.Core = Core
	self.TrajectoryBeam = Core:Get("TrajectoryBeam")
	self.Aiming = false
	self.BaseFOV = Camera.FieldOfView -- default fov
end

function CameraController:AimZoom(FoodName, RaycastParams)
	if self.Aiming then return end
	self.Aiming = true

	local tween = TweenService:Create(
		Camera,
		TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{FieldOfView = AIM_FOV}
	)
	tween:Play()

	if not LocalPlayer.Character then return end
	local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not HRP then return end

	local function getTrajectoryData()
		local foodData = FoodIndex[FoodName]
		if not foodData then return nil end

		local Origin = HRP.Position + HRP.CFrame.LookVector * 5
		local Direction = (Mouse.Hit.Position - Origin).Unit
		local Speed = foodData.Speed or 150
		local Velocity = Direction * Speed + Vector3.new(0,10,0)

		return {
			Origin = Origin,
			Velocity = Velocity,
			Gravity = foodData.Gravity or Vector3.new(0, -50, 0),
			RaycastParams = RaycastParams,
		}
	end
	self.TrajectoryBeam:Enable(getTrajectoryData)
end

function CameraController:StopAim()
	if not self.Aiming then return end
	self.Aiming = false

	local tween = TweenService:Create(
		Camera,
		TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{FieldOfView = self.BaseFOV}
	)
	tween:Play()

	self.TrajectoryBeam:Disable()
end

return CameraController
