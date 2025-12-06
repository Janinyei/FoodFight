--janin 11/15/25
--rather have this than food that instantly disappears
local FoodSplat = {}
--Services--
local ReplicatedStorage = game.ReplicatedStorage
local Assets = ReplicatedStorage.Assets
local Effects = Assets.Effects
local GeneralEffects = Effects.General
local Debris = game:GetService("Debris")




--variables--



--Imports--
local Modules = ReplicatedStorage.Modules
local Functions = require(Modules.Utils.Functions)

function FoodSplat:Play(data)
    print(data)

   if Functions.FindCharacter(data.Obj) then return end --doesn't splat on characters

    local DecalPart = GeneralEffects.FoodSplat:Clone()
    local Decal = DecalPart.Decal

    DecalPart.Transparency = 1
    DecalPart.Parent = workspace.VisualEffectsCache --make sure to use so raycast ignores are easier
    DecalPart.Position = data.Position
    DecalPart.Size = Vector3.new(data.Radius, data.Radius, 0.1)
    
    DecalPart.CFrame = CFrame.lookAlong(data.Position + data.Normal * 0.01, -data.Normal)
    Decal.Color3 = data.Color or Color3.fromRGB(255, 255, 255)
    

    --[[local newParticle = Particle:Clone() --part
    newParticle.Parent = workspace
    newParticle.Position = data.Position
    newParticle.CFrame = CFrame.lookAlong(newParticle.Position + data.Normal * 0.01, -data.Normal)
    Functions.Emit(newParticle)
    
    newParticle.FoodSplat.Mark.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, self:GetFoodColor(data)), ColorSequenceKeypoint.new(1, self:GetFoodColor(data))})
    
    ]]

    

    Debris:AddItem(DecalPart, 5)
end



return FoodSplat