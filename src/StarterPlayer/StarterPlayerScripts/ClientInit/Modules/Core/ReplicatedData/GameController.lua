--purpose: controls and fires signals from replicated data of the game
--note: will use to replicate other necessary values in the future

local GameController = {}

local Signal = require(game.ReplicatedStorage.Modules.Utils.Signal)

function GameController:Init(Core)
	self.SharedRemotes = Core:Get("SharedRemotes")

	self.GameEvent = self.SharedRemotes:GetEvent("GameEvent")
	self.GameData = {
		InGame = false,
		CurrentMode = "",
		CurrentMap = "",
		ServerData = {--lowk idk
			Region = ""
		},
		PlayerCount = -999
	}

	self.GameDataChanged = Signal.new()
end

--as simple as this
function GameController:Start()
	--initial game data invokation--

	--- init
	local GameData = self.GameEvent:Invoke(60, "GetGameData")

	if GameData then
		self.GameData = GameData
		self.GameDataChanged:Fire(GameData)
	end

	self.GameEvent:Connect(function(data)
        print('game data received')
        print(data)
		self.GameData = data
		self.GameDataChanged:Fire(data)
	end)


end

return GameController
