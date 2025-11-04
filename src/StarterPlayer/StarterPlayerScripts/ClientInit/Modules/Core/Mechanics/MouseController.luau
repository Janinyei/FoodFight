--not to be confused with PlayerModule mouse control scripts. Although this script does work with it.
--Purpose: control mouse in different states and part of the game for easy flow and access for players to use UI
--janin 11/1/25

--Note: Eventually will have to refactor this since the WaitForChilds could cause yielding issues with the module loader



--Services--
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

--Variables--
local LocalPlayer = Players.LocalPlayer

--Constants--
local MOUSE_LOCK_OFFSET = Vector3.new(3, 0, 0)
local MOUSE_LOCK_ICON = "rbxassetid://86236387189138"
--Imports--

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
--basically helps whenever we want to unlock the mouse to use UI 
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


function MouseController:Init()
    self.cameraController = CameraModule.activeCameraController
    self.mouseLockController = CameraModule.activeMouseLockController
    self.MouseBehavior = Enum.MouseBehavior.LockCenter
    self.Offset = MOUSE_LOCK_OFFSET
end

function MouseController:Start()
	print(CameraModule)
	self:Unlock()
   
end

function MouseController:Lock()
    if self.cameraController then
        self.cameraController:SetIsMouseLocked(true)
        self.cameraController:SetMouseLockOffset(self.Offset)
        CameraUtils.setMouseIconOverride(MOUSE_LOCK_ICON)
    end
end

function MouseController:Unlock()
    if self.cameraController then
        self.cameraController:SetIsMouseLocked(false)
        CameraUtils.restoreMouseIcon()
    end
end


function MouseController:ChangeMouseBehavior(behavior : Enum.MouseBehavior)
    self.MouseBehavior = behavior
end

return MouseController
