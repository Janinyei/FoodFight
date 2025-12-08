-- Imports
local Functions = require(game.ReplicatedStorage.Modules.Utils.Functions)

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Egg = {}
local AssetsFolder = ReplicatedStorage.Assets
local Effects = AssetsFolder.Effects
local EggVFXFolder = Effects.Food.Egg.Visual

function Egg:Init(Core)
    self.VFXController = Core:Get("VFXController")
end

function Egg:OnHit(VFXData)
    
    local EggSplash = EggVFXFolder.EggSplash:Clone()
    EggSplash.Position = VFXData.HitResult.Position
    EggSplash.Parent = workspace.VisualEffectsCache
    Debris:AddItem(EggSplash, 5)

    Functions.Emit(EggSplash)


   self.VFXController:PlayEffect("FoodSplat", {
        Position = VFXData.HitResult.Position,
        Normal = VFXData.HitResult.Normal,
        Obj = VFXData.HitResult.Instance,
        FoodName = VFXData.Name,
        Color = Color3.fromRGB(227, 251, 198),
        Radius = 10
    })
end


function Egg:SpecialHit(VFXData, VFXController)
 
end

return Egg