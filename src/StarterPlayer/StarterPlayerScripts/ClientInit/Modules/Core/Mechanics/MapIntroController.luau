local MapIntroController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Spring = require(ReplicatedStorage.Modules.Utils.Spring)
local Signal = require(ReplicatedStorage.Modules.Utils.Signal)

function MapIntroController:Init(Core)
	self.Core = Core
	self.SharedRemotes = Core:Get("SharedRemotes")
	self.MapIntroEvent = self.SharedRemotes:GetEvent("MapIntroEvent")
	self.CharacterEvent = self.SharedRemotes:GetEvent("CharacterEvent")
	
	self.RunService = game:GetService("RunService")
	self.Players = game:GetService("Players")
	self.Camera = workspace.CurrentCamera

	self.Completed = Signal.new()
end

function MapIntroController:Start()
	self.CameraController = self.Core:Get("CameraController")
	self.Completed:Connect(function()
		self.CharacterEvent:Fire("Spawn")
	end)

	self.MapIntroEvent:Connect(function(mapName)
		local mapModel = workspace.Map:FindFirstChild(mapName)
		if mapModel then
			self:Play(mapModel)
		end
	end)
end

function MapIntroController:Play(mapModel)
	local cutsceneModel = mapModel:FindFirstChild("Cutscene")
	local focusPoint = cutsceneModel and cutsceneModel:FindFirstChild("FocusPoint")
	local cameraAttach = focusPoint and focusPoint:FindFirstChild("CameraAttachment")

	if not (cutsceneModel and focusPoint and cameraAttach) then
		return
	end

	self.CameraController:SetEnabled(false)

	local oldType = self.Camera.CameraType
	local oldFOV = self.Camera.FieldOfView
	self.Camera.CameraType = Enum.CameraType.Scriptable

	local rotateSpring = Spring.new(0)
	rotateSpring.Target = 0.785 -- 45 degrees
	rotateSpring.Speed = 1
	rotateSpring.Damper = 1
	
	local zoomSpring = Spring.new(0)
	zoomSpring.Target = 20 -- zoom distance
	zoomSpring.Speed = 1
	zoomSpring.Damper = 1

	local initialFocusCF = focusPoint.CFrame
	local initialAttachCF = cameraAttach.CFrame

	local connection
	connection = self.RunService.RenderStepped:Connect(function()
		local rot = rotateSpring.Position
		local zoom = zoomSpring.Position

		focusPoint.CFrame = initialFocusCF * CFrame.Angles(0, rot, 0)
		cameraAttach.CFrame = initialAttachCF * CFrame.new(0, 0, -zoom)

		self.Camera.FieldOfView = 30
		self.Camera.CFrame = CFrame.lookAt(cameraAttach.WorldPosition, focusPoint.Position)

		local isSettled = math.abs(rotateSpring.Velocity) < 0.001 
			and math.abs(rotateSpring.Target - rotateSpring.Position) < 0.001
			and math.abs(zoomSpring.Velocity) < 0.001
			and math.abs(zoomSpring.Target - zoomSpring.Position) < 0.001

		if isSettled then
			connection:Disconnect()
			
			self.Camera.CameraType = oldType
			self.Camera.FieldOfView = oldFOV
			
			self.CameraController:SetEnabled(true)
			self.Completed:Fire()
		end
	end)
end

return MapIntroController