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

	--Mouse/Shiftlock stuff
	self.ShiftLockEnabled = false
	--Constants/Config idk--

	self.cameraController = CameraModule.activeCameraController
	self.mouseLockController = CameraModule.activeMouseLockController

	self.MOUSE_LOCK_OFFSET = Vector3.new(1.75, 1, 0)
	self.CAMERA_TRANSITION_IN_SPEED = 6
	self.CAMERA_TRANSITION_OUT_SPEED = 10
	self.MOUSE_LOCK_ICON = "rbxassetid://103003009346193"

	self.CAMERA_AIM_OFFSET = Vector3.new(2,0,-2)

	--springs--
	self.OffsetSpring = Spring.new(Vector3.zero)
	self.OffsetSpring.Damper = 0.7
	
	self.CameraLerpSpring = Spring.new(Vector3.zero)

	--signals--

	--janitor--
	self.ShiftLockJanitor = Janitor.new()
end

function CameraController:Start()
	

	self.InputController:SetActionCallback("ToggleShiftLock", function(state, inputObj)
		if state == Enum.UserInputState.Begin then
			self:ToggleShiftLock()
		end
	end)

	local CameraLerpSpring = self.CameraLerpSpring
	--test.Damper = 0.65
	CameraLerpSpring.Speed = 20

	--constant camera spring update
	self.ShiftLockJanitor:Add(RunService.RenderStepped:Connect(function(dt) --probably don't need a janitor since this isn't being cleaned up but you never know

		CameraLerpSpring.Target = Camera.CFrame.Position
	
	
		if  self.Aiming then --allows for stable aiming
		Camera.CFrame = Camera.CFrame * CFrame.new(self.OffsetSpring.Position) --doesn't use camera lerp
	else
		Camera.CFrame = ((Camera.CFrame - Camera.CFrame.Position) + CameraLerpSpring.Position) * CFrame.new(self.OffsetSpring.Position)		
		
		end
	end))
end

function CameraController:ToggleShiftLock(Enable: boolean)
	if Enable ~= nil then
		self.ShiftLockEnabled = Enable
	else
		self.ShiftLockEnabled = not self.ShiftLockEnabled
	end

	self:_updateMouseBehavior()
	self:_adjustLockOffset()
end

function CameraController:ToggleAimZoom(Enable : boolean)

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

return CameraController
