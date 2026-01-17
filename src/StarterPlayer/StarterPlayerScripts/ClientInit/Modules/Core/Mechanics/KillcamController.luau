--Purpose: Handles the killcam logic when a player dies
--tzu 12/25/25

local KillcamController = {}

--Services--

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local TweenService = game:GetService("TweenService")

--Variables--
function KillcamController:Init(Core)
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")
	self.ScreenGuiController = Core:Get("ScreenGuiController")
	self.CameraController = Core:Get("CameraController")
	self.SpectateGuiController = Core:Get("SpectateGui")

	--Gui--
	self.KillcamGui = PlayerGui.Killcam
end

function KillcamController:Start() end

function KillcamController:StartKillcam(EliminationData)
	-- If suicide or environment, go straight to general spectating
	if not KillerPlayer then
		--    self.SpectateGui:SpectateRandom()
		return
	end

	local KillerChar = KillerPlayer.Character

	
	if not KillerChar then --or-- not KillerChar:FindFirstChild("HumanoidRootPart") then
		self.SpectateGui:SpectateRandom()
	end

	-- 1. Focus Camera on Killer
	self.CameraController:Spectate(KillerPlayer)

	-- 2. Optional: Show "Killed By [Name]" UI
	--insert cinematic bars

	local KillcamGui = self.KillcamGui
	KillcamGui.Enabled = true

	local Topbar = KillcamGui.TopFrame
	local BottomBar = KillcamGui.BottomFrame

	--Tween bars into frame
	TweenService:Create(
		Topbar,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ Position = UDim2.fromScale(0.5, 0) }
	):Play()
	TweenService:Create(
		BottomBar,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ Position = UDim2.fromScale(0.5, 1) }
	):Play()

	-- 3. Transition to general spectating after a few seconds
	task.delay(4, function()
		-- Only transition if we haven't respawned yet
	--	if game.Players.LocalPlayer.Character == nil or game.Players.LocalPlayer.Character.Parent == nil then
			self.ScreenGuiController:SetScreen("Spectate") --makes spectate controls visible
			TweenService:Create(
				Topbar,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ Position = UDim2.fromScale(0.5, -1) }
			):Play()
			TweenService:Create(
				BottomBar,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ Position = UDim2.fromScale(0.5, 2) }
			):Play()
	--	end
	end)


	--idk what this is, do smtn abt it Tzu
	if self.CameraController.CameraLerpSpring then
		local OldSpeed = self.CameraController.CameraLerpSpring.Speed
		self.CameraController.CameraLerpSpring.Speed = 3
		task.delay(1.5, function()
			self.CameraController.CameraLerpSpring.Speed = OldSpeed or 20
		end)
	end
end

function KillcamController:ShowRespawnMenu()
	self.ScreenGuiController:SetScreen("Menu")
end

return KillcamController
