local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()


local CharacterController = require(LocalPlayer.PlayerScripts.ClientInit.Modules.Core.CharacterController)


CharacterController:SetupCharacter(Character)

