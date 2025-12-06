--janin 11/15/25
--rather have this than food that instantly disappears
local FoodSplat = {}
--Services--
local ReplicatedStorage = game.ReplicatedStorage
local Assets = ReplicatedStorage.Assets
local VFXAssets = Assets.VFX
local Debris = game:GetService("Debris")




--variables--
local FoodColors = {
    ["Egg"] = Color3.fromRGB(255, 203, 48),
    ["Tomato"] = Color3.fromRGB(255, 0, 0),

}


--Imports--
local Modules = ReplicatedStorage.Modules
local Functions = require(Modules.Utils.Functions)

function FoodSplat:Play(data)
    print(data)

   if Functions.FindCharacter(data.Obj) then return end --doesn't splat on characters

    local DecalPart = VFXAssets.General.FoodSplat:Clone()
    local Decal = DecalPart.Decal

    DecalPart.Transparency = 1
    DecalPart.Parent = workspace.VisualEffectsCache --make sure to use so raycast ignores are easier
    DecalPart.Position = data.Position
    DecalPart.CFrame = CFrame.lookAlong(data.Position + data.Normal * 0.01, -data.Normal)
    Decal.Color3 = self:GetFoodColor(data)
    
    


    --[[local newParticle = Particle:Clone() --part
    newParticle.Parent = workspace
    newParticle.Position = data.Position
    newParticle.CFrame = CFrame.lookAlong(newParticle.Position + data.Normal * 0.01, -data.Normal)
    Functions.Emit(newParticle)
    
    newParticle.FoodSplat.Mark.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, self:GetFoodColor(data)), ColorSequenceKeypoint.new(1, self:GetFoodColor(data))})
    
    ]]

    

    Debris:AddItem(DecalPart, 5)


end

function FoodSplat:GetFoodColor(data)
    local foodName = data.FoodName
    local color = FoodColors[foodName]
    if color then
        return color
    else
        return Color3.fromRGB(255, 255, 255) --default white
    end
end


return FoodSplat