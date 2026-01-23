-- CameraController
-- purpose: controls camera updating movement, shift lock offset, aiming zooming, etc
-- tzu 12/06/25
--refactored by janin 12/18/25
--note: introduced using the Spring module to help with smoother camera movement
--note: I took some inspiration from the popular SmoothShiftLock module
local CameraController = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- Modules
local Modules = ReplicatedStorage.Modules
local FoodConfigs = Modules.Info.FoodCombatConfigs

--Imports--
local Modules = ReplicatedStorage.Modules
local Spring = require(Modules.Utils.Spring)
local Janitor = require(Modules.Utils.Janitor)
local CameraShaker = require(Modules.Utils.CameraShaker)

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--PlayerModule variables--
local PlayerModule = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
local CameraModule = require(PlayerModule:WaitForChild("CameraModule"))
local CameraUtils = require(PlayerModule.CameraModule:WaitForChild("CameraUtils"))
local BaseCamera = require(PlayerModule.CameraModule:WaitForChild("BaseCamera"))
local CameraUI = require(PlayerModule.CameraModule:WaitForChild("CameraUI"))
local CameraInput = require(PlayerModule.CameraModule:WaitForChild("CameraInput"))
local CameraToggleStateController = require(PlayerModule.CameraModule:WaitForChild("CameraToggleStateController"))
local MouseController = {}

--base cam override
local UserGameSettings = UserSettings():GetService("UserGameSettings")

--overrides base camera to have custom mouse behavior
--serves to unlock mouse whenever mouse  behavior is set to default
function BaseCamera:UpdateMouseBehavior()
	local blockToggleDueToClickToMove = UserGameSettings.ComputerMovementMode == Enum.ComputerMovementMode.ClickToMove

	if self.isCameraToggle and blockToggleDueToClickToMove == false then
		CameraUI.setCameraModeToastEnabled(true)
		CameraInput.enableCameraToggleInput()
		CameraToggleStateController(self.inFirstPerson)
	else
		CameraUI.setCameraModeToastEnabled(false)
		CameraInput.disableCameraToggleInput()

		-- first time transition to first person mode or mouse-locked third person
		if self.inFirstPerson or self.inMouseLockedMode then
			CameraUtils.setRotationTypeOverride(Enum.RotationType.CameraRelative)
			CameraUtils.setMouseBehaviorOverride(MouseController.MouseBehavior)
		else
			CameraUtils.restoreRotationType()

			local rotationActivated = CameraInput.getRotationActivated()
			if rotationActivated then
				CameraUtils.setMouseBehaviorOverride(Enum.MouseBehavior.LockCurrentPosition)
			else
				CameraUtils.restoreMouseBehavior()
			end
		end
	end
end

function CameraController:Init(Core)
	self.Core = Core
	self.CharacterController = Core:Get("CharacterController")
	self.InputController = Core:Get("InputController")

	--variables--
	self.Aiming = false
	self.BaseFOV = Camera.FieldOfView -- default fov
	self.TargetFOV = self.BaseFOV
	self.FOVSpeed = 10

	-- FOV Spring
	self.FOVSpring = Spring.new(self.BaseFOV)
	self.FOVSpring.Speed = 20
	self.FOVSpring.Damper = 0.7

	--Mouse/Shiftlock stuff
	self.ShiftLockEnabled = false
	--Constants/Config idk--

	self.cameraController = CameraModule.activeCameraController
	self.mouseLockController = CameraModule.activeMouseLockController

	self.MOUSE_LOCK_OFFSET = Vector3.new(1.75, 1, 0)
	self.CAMERA_TRANSITION_IN_SPEED = 6
	self.CAMERA_TRANSITION_OUT_SPEED = 10
	self.MOUSE_LOCK_ICON = "rbxassetid://103003009346193"

	self.CAMERA_AIM_OFFSET = Vector3.new(2, 0, -2)

	-- Recoil Settings
	self.RECOIL_DEFAULTS = {
		recoilAmount = 2,
		sideAmount = 1,
		recoilSpeed = 0.05,
		recoverSpeed = 0.5,
		randomness = 0.2,
	}
	self.ActiveRecoils = {}
	self.RecoilOffset = Vector2.zero -- Smoothed accumulated recoil
	self.LastRecoilCF = CFrame.new() -- Tracked to prevent accumulation
	self.LastShakeCF = CFrame.new() -- Same for shake

	--springs--
	self.OffsetSpring = Spring.new(Vector3.zero)
	self.OffsetSpring.Damper = 0.95

	self.CameraLerpSpring = Spring.new(Vector3.zero)

	--signals--

	--janitor--
	self.ShiftLockJanitor = Janitor.new()

	-- camera shaker --
	self.Shaker = CameraShaker.new(Enum.RenderPriority.Camera.Value, function() end)

	self.Enabled = true
end

function CameraController:Start()
	self.FoodCombatController = self.Core:Get("FoodCombatController")

	self.InputController:SetActionCallback("ToggleShiftLock", function(state, _)
		if state == Enum.UserInputState.Begin then
			self:ToggleShiftLock()
		end
	end)

	self.FoodCombatController.Fired:Connect(function()
		self:ApplyRecoil()
	end)

	self.FoodCombatController.UltimateActivated:Connect(function()
		self:SetDynamicFOV(90, 0.5)
	end)

	self.FoodCombatController.UltimateDeactivated:Connect(function()
		self:SetDynamicFOV(self.BaseFOV, 0.5)
	end)

	self.FoodCombatController.DamageDealt:Connect(function(data)
		local isCritical = data.Combat and data.Combat.Critical
		local isUltimate = data.Combat and data.Combat.Ultimate

		self:FOVPunch(isCritical and -4 or -2, 0.1)

		if isCritical then
			self:Shake(0.4, 15, 0.05, 0.3)
			self:HitPause(0.07)
		elseif isUltimate then
			self:Shake(0.5, 20, 0.05, 0.5)
			self:HitPause(0.1)
		else
			self:Shake(0.175, 12, 0.05, 0.1)
		end
	end)

	local CameraLerpSpring = self.CameraLerpSpring
	--test.Damper = 0.65
	CameraLerpSpring.Speed = 500

	--constant camera spring update
	self.ShiftLockJanitor:Add(
		RunService.RenderStepped:Connect(
			function(dt) 
				if not self.Enabled then return end
				
				CameraLerpSpring.Target = Camera.CFrame.Position

				--[[
				if self.Aiming then --allows for stable aiming
				
									Camera.CFrame = Camera.CFrame * CFrame.new(self.OffsetSpring.Position)
								else
								
									Camera.CFrame = ((Camera.CFrame - Camera.CFrame.Position) + CameraLerpSpring.Position)
										* CFrame.new(self.OffsetSpring.Position)
								end
				]]
				

				Camera.CFrame = Camera.CFrame * CFrame.new(self.OffsetSpring.Position)
				-- 1. Clean up/Undo previous frame's offsets to prevent accumulation
				Camera.CFrame = Camera.CFrame * self.LastRecoilCF:Inverse() * self.LastShakeCF:Inverse()

				-- 2. Update Recoil Math
				local accumulatedTarget = Vector2.zero
				for i = #self.ActiveRecoils, 1, -1 do
					local recoil = self.ActiveRecoils[i]
					recoil.elapsedTime = recoil.elapsedTime + dt

					local weight = 0
					if recoil.isRising then
						local progress = math.min(recoil.elapsedTime / recoil.config.recoilSpeed, 1)
						weight = 1 - (1 - progress) ^ 2 -- Quadratic ease-out for the "kick"
						if progress >= 1 then
							recoil.isRising = false
							recoil.elapsedTime = 0
						end
					else
						local progress = math.max(1 - recoil.elapsedTime / recoil.config.recoverSpeed, 0)
						weight = progress ^ 3 -- Cubic ease-in for the "recovery"
						if progress <= 0 then
							table.remove(self.ActiveRecoils, i)
						end
					end

					accumulatedTarget = accumulatedTarget + recoil.target * weight
				end

				-- 3. Smoothly transition the recoil offset to return to center
				self.RecoilOffset = self.RecoilOffset + (accumulatedTarget - self.RecoilOffset) * dt * 10

				-- 4. Re-apply fresh offsets
				self.LastRecoilCF = CFrame.Angles(math.rad(self.RecoilOffset.Y), math.rad(self.RecoilOffset.X), 0)
				self.LastShakeCF = self.Shaker:Update(dt)

				Camera.CFrame = Camera.CFrame * self.LastRecoilCF * self.LastShakeCF

				-- Update FOV
				Camera.FieldOfView = self.FOVSpring.Position
			end
		)
	)
end

function CameraController:ToggleShiftLock(Enable: boolean)
	if Enable ~= nil then
		self.ShiftLockEnabled = Enable
	else
		self.ShiftLockEnabled = not self.ShiftLockEnabled
	end

	if self.CharacterController and self.CharacterController.ParkourConfig then
		self.CharacterController.ParkourConfig.rotateHRPWithCamera = self.ShiftLockEnabled
	end

	self:_updateMouseBehavior()
	self:_adjustLockOffset()
end

--sets cam subject to specific player's
function CameraController:Spectate(Target: Player | Character?)
	local CameraSubject

	if Target:IsA("Player") then
		CameraSubject = Target.Character.HumanoidRootPart
	elseif Target:IsA("Model") then
		CameraSubject = Target.HumanoidRootPart
	end

	if CameraSubject then
	Camera.CameraSubject = CameraSubject
	end
end

function CameraController:ToggleAimZoom(Enable: boolean)
	if Enable then
		self.OffsetSpring.Target = self.CAMERA_AIM_OFFSET
		self.OffsetSpring.Speed = 20
		self.OffsetSpring.Damper = 1

		--	self.CameraLerpSpring.Speed = 100

		self.Aiming = true
	else
		self:_adjustLockOffset()
		self.Aiming = false
	end
end

--is this function even being used lol?
function CameraController:SetSpectate(IsSpectating: boolean, Position: Vector3?)
	if IsSpectating and Position then
		Camera.CameraType = Enum.CameraType.Scriptable
		local cameraPos = Position + Vector3.new(100, 80, 100)
		Camera.CFrame = CFrame.lookAt(cameraPos, Position)
	else
		Camera.CameraType = Enum.CameraType.Custom
		if LocalPlayer.Character then
			local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
			if humanoid then
				Camera.CameraSubject = humanoid
			end
		end
	end
end

function CameraController:FOVPunch(amount: number, duration: number)
	self.FOVSpring.Position = self.FOVSpring.Position + amount
end

function CameraController:SetDynamicFOV(targetFOV: number, duration: number)
	self.FOVSpring.Target = targetFOV
end

function CameraController:ApplyRecoil(multiplier: number?, config: table?)
	multiplier = multiplier or 1
	local cfg = config or self.RECOIL_DEFAULTS

	-- Clean targeted recoil math
	local rand = cfg.randomness
	local randomMult = function()
		return 1 + (math.random() * 2 * rand - rand)
	end

	local targetX = cfg.sideAmount * (math.random() - 0.5) * 2 * randomMult() * multiplier
	local targetY = cfg.recoilAmount * randomMult() * multiplier

	table.insert(self.ActiveRecoils, {
		elapsedTime = 0,
		target = Vector2.new(targetX, targetY),
		isRising = true,
		config = cfg,
	})
end

--[[
function CameraController:HitPause(duration: number)
	local startTime = os.clock()
	while os.clock() - startTime < duration do
		-- Busy wait to simulate frame freeze
		-- Note: This is usually discouraged but specifically requested for "frame freeze" feedback
	end
end
]]

function CameraController:HitPause(duration: number)
	local startTime = os.clock()
	while os.clock() - startTime < duration do
		-- Busy wait to simulate frame freeze
		-- Note: This is usually discouraged but specifically requested for "frame freeze" feedback
	end
end

----------------------------Camera Shaking Effects-------------------

function CameraController:Shake(
	presetName: string | table | number,
	magnitude: number?,
	roughness: number?,
	fadeInTime: number?,
	fadeOutTime: number?,
	posInfluence: Vector3?,
	rotInfluence: Vector3?
)
	if type(presetName) == "string" then
		local preset = CameraShaker.Presets[presetName]
		if preset then
			self.Shaker:Shake(preset)
		end
	elseif type(presetName) == "table" then
		self.Shaker:Shake(presetName)
	else
		local actualMag = type(presetName) == "number" and presetName or magnitude
		local actualRough = type(presetName) == "number" and magnitude or roughness
		local actualFadeIn = type(presetName) == "number" and roughness or fadeInTime
		local actualFadeOut = type(presetName) == "number" and fadeInTime or fadeOutTime

		if actualMag then
			local instance = self.Shaker:ShakeOnce(
				actualMag,
				actualRough or 1,
				tonumber(actualFadeIn) or 0.1,
				tonumber(actualFadeOut) or 0.5
			)
			instance.PositionInfluence = posInfluence or Vector3.new(0, 0, 0)
			instance.RotationInfluence = rotInfluence or Vector3.new(0.4, 0.4, 0.4)
		end
	end
end

function CameraController:ShakeSustain(presetName: string | table)
	local preset = type(presetName) == "string" and CameraShaker.Presets[presetName] or presetName
	if preset then
		return self.Shaker:ShakeSustain(preset)
	end
end

--------private functions-------

--more shift lock stuff
function CameraController:_adjustLockOffset()
	if self.ShiftLockEnabled == true then
		self.OffsetSpring.Speed = self.CAMERA_TRANSITION_IN_SPEED
		self.OffsetSpring.Target = self.MOUSE_LOCK_OFFSET
		CameraUtils.setMouseIconOverride(self.MOUSE_LOCK_ICON)

		-- self.cameraController:SetIsMouseLocked(true) --eventually change to custom character orientation
		--  self.cameraController:SetMouseLockOffset(self.Offset)
	else
		--	self.cameraController:SetIsMouseLocked(false)
		self.OffsetSpring.Speed = self.CAMERA_TRANSITION_OUT_SPEED
		self.OffsetSpring.Target = Vector3.zero
		CameraUtils.restoreMouseIcon()
	end
end

function CameraController:_updateMouseBehavior()
	UIS.MouseBehavior = (self.ShiftLockEnabled and Enum.MouseBehavior.LockCenter) or Enum.MouseBehavior.Default
end

function CameraController:SetEnabled(State: boolean)
	self.Enabled = State
	
	if State then
		self:_updateMouseBehavior()
		self:_adjustLockOffset()
	else
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		CameraUtils.restoreMouseIcon()
	end
end

return CameraController
