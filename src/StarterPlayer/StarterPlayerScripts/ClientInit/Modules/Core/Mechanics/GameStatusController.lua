-- CharacterController
-- Manages clientsided character states (Lobby/Game)
-- Tzu 12/06/25

--note: rename to GameStatusController -librium 12/12/25

local GameStatusController = {}

function GameStatusController:Init(Core)
	self.Core = Core
	self.GameStatusEvent = Core:Get("SharedRemotes"):GetEvent("GameStatusEvent")
	self.CameraController = Core:Get("CameraController")
	self.ScreenGuiController = Core:Get("ScreenGuiController")
	self.MouseController = Core:Get("MouseController")
end

function GameStatusController:Start()
	self.GameStatusEvent:Connect(function(action, data)
		if action == "SetState" then
			if data.State == "Lobby" then
				self:SetLobbyState(data.Position)
			elseif data.State == "Game" then
				self:SetGameState()
			end
		end
	end)
end

function GameStatusController:SetLobbyState(position)
	self.CameraController:SetSpectate(true, position)
	self.ScreenGuiController:SetScreen("Menu")
	self.MouseController:Unlock()
end

function GameStatusController:SetGameState()
	self.CameraController:SetSpectate(false)
	print("setting the screen to HUD")
	self.ScreenGuiController:SetScreen("HUD")
	self.MouseController:Lock()
end

return GameStatusController
