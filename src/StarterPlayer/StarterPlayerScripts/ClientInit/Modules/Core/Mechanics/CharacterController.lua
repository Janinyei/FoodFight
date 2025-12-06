-- CharacterController
-- Manages clientsided character states (Lobby/Game)
-- Tzu 12/06/25

local CharacterController = {}

function CharacterController:Init(Core)
	self.Core = Core
	self.CharacterEvent = Core:Get("SharedRemotes"):GetEvent("CharacterEvent")
	self.ProjectileController = Core:Get("ProjectileController")
	self.CameraController = Core:Get("CameraController")
end

function CharacterController:Start()
	self.CharacterEvent:Connect(function(action, data)
		if action == "SetState" then
			if data.State == "Lobby" then
				self:SetLobbyState(data.Position)
			elseif data.State == "Game" then
				self:SetGameState()
			end
		end
	end)
end

function CharacterController:SetLobbyState(position)
	self.CameraController:SetSpectate(true, position)
end

function CharacterController:SetGameState()
	self.CameraController:SetSpectate(false)
end

return CharacterController
