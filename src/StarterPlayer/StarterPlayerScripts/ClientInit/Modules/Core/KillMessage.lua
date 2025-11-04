local Players = game:GetService("Players")
local AnimNation = require(game.ReplicatedStorage.Modules.Utils.AnimNation)

local KillMessage = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DEFAULT_COIN_REWARD = 100
local DEFAULT_EXP_REWARD = 100

function KillMessage:ShowKill(targetName, coins, exp)
	coins = coins or DEFAULT_COIN_REWARD
	exp = exp or DEFAULT_EXP_REWARD

end

return KillMessage