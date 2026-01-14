--Purpose: Handles the killcam logic when a player dies
--tzu 12/25/25

local KillcamController = {}

--Services--
local Workspace = game:GetService("Workspace")

--Variables--
local Camera = Workspace.CurrentCamera

function KillcamController:Init(Core)
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")
	self.ScreenGuiController = Core:Get("ScreenGuiController")
	self.CameraController = Core:Get("CameraController")
	self.PlayerEliminated = Core:Get("FoodCombatController").PlayerEliminated
end

function KillcamController:Start()
	self.PlayerEliminated:Connect(function(targetPlayer, data)
		print(targetPlayer)
		print(data)
	end)
end

function KillcamController:StartKillcam(KillerPlayer)
	if not KillerPlayer then
		-- for example this is if you reset or something
		self:ShowRespawnMenu()
		return
	end

	local KillerChar = KillerPlayer.Character
	if not KillerChar then
		self:ShowRespawnMenu()
		return
	end

	local KillerHum = KillerChar:FindFirstChild("Humanoid")
	if not KillerHum or KillerHum.Health <= 0 then
		self:ShowRespawnMenu()
		return
	end

	Camera.CameraSubject = KillerHum

	if self.CameraController.CameraLerpSpring then
		local OldSpeed = self.CameraController.CameraLerpSpring.Speed
		self.CameraController.CameraLerpSpring.Speed = 3
		task.delay(1.5, function()
			self.CameraController.CameraLerpSpring.Speed = OldSpeed or 20
		end)
	end

	task.delay(3, function()
		self:ShowRespawnMenu()
	end)
end

function KillcamController:ShowRespawnMenu()
	self.ScreenGuiController:SetScreen("Menu")

	-- TODO:
end

return KillcamController
