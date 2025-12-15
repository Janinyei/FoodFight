--generic effect to make flashy 'poof' clouds lol
--kinda like shadow clone ninja stuff idk

local PoofClouds = {}
--Services--
local ReplicatedStorage = game.ReplicatedStorage
local Assets = ReplicatedStorage.Assets
local Effects = Assets.Effects
local GeneralEffects = Effects.General
local Debris = game:GetService("Debris")

local Modules = ReplicatedStorage.Modules
local Functions = require(Modules.Utils.Functions)

function PoofClouds:Play(data)
	local Pos = data.Position

	local Effect: Attachment = GeneralEffects.PoofClouds:Clone()
	Effect.Parent = workspace.VisualEffectsCache
	Effect.CFrame = CFrame.new(Pos)

	Functions.Emit(Effect)

	Debris:AddItem(Effect, 5)
end

return PoofClouds
