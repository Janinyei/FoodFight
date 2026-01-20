--purpose: controls and fires signals from replicated data of the game
--note: will use to replicate other necessary values in the future

local GameController = {}

local Signal = require(game.ReplicatedStorage.Modules.Utils.Signal)

function GameController:Init(Core)
	self.SharedRemotes = Core:Get("SharedRemotes")

	self.GameEvent = self.SharedRemotes:GetEvent("GameEvent")
	self.GameData = {
		InGame = false,
	}

	self.GameDataChanged = Signal.new()
end

--as simple as this
function GameController:Start()
	self.GameEvent:Connect(function(data)
        print('game data received')
        print(data)
		self.GameData = data
		self.GameDataChanged:Fire(data)
	end)
end

return GameController
