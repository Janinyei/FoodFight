--not to be confused with PlayerModule mouse control scripts. Although this script does work with it.
--Purpose: control mouse in different states and part of the game for easy flow and access for players to use UI  do
--note: handles shift locking too
--janin 11/1/25

--Note: Eventually will have to refactor this since the WaitForChilds could cause yielding issues with the module loader

--Services--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Variables--
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
--Constants--
local MOUSE_LOCK_OFFSET = Vector3.new(0, 3, 0)

--local MOUSE_LOCK_ICON = "rbxassetid://86236387189138"
local MOUSE_LOCK_ICON = "rbxassetid://103003009346193"

local MouseController = {}

function MouseController:Init()
	--self.cameraController = CameraModule.activeCameraController
--	self.mouseLockController = CameraModule.activeMouseLockController
	--self.MouseBehavior = Enum.MouseBehavior.LockCenter

	self.Offset = MOUSE_LOCK_OFFSET
	self.Enabled = true
	--self.MouseLocked = self.cameraController:GetIsMouseLocked()
	--this is because this module controls the HRP's orientation by 

	--
end

function MouseController:Start()
	--self:Unlock()

end



function MouseController:Lock()
	if self.cameraController then
		self.cameraController:SetIsMouseLocked(true)
		self.MouseLocked = self.cameraController:GetIsMouseLocked()

		self.OffsetSpring.Speed = CAMERA_TRANSITION_IN_SPEED
		self.OffsetSpring.Target = self.Offset
		--  self.cameraController:SetMouseLockOffset(self.Offset)

		--set up run service event for smooth toggle

		CameraUtils.setMouseIconOverride(MOUSE_LOCK_ICON)
	end
end

function MouseController:Unlock()
	if self.cameraController then
		self.cameraController:SetIsMouseLocked(false)
		self.MouseLocked = self.cameraController:GetIsMouseLocked()

		self.OffsetSpring.Speed = CAMERA_TRANSITION_OUT_SPEED
		self.OffsetSpring.Target = Vector3.new(0, 0, 0)

		CameraUtils.restoreMouseIcon()

		
	end
end

function MouseController:ChangeMouseBehavior(behavior: Enum.MouseBehavior)
	self.MouseBehavior = behavior
end

return MouseController
