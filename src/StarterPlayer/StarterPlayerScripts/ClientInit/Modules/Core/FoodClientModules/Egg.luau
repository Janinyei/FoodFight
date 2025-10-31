-- Imports
local Functions = require(game.ReplicatedStorage.Modules.Utils.Functions)

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Egg = {}
local VFXFolder = ReplicatedStorage.VFX
local AssetsFolder = ReplicatedStorage.Assets

function Egg:OnHit(_, HitResult)
    local Wind = VFXFolder.ChickenWind:Clone()
    local ChickenTemplate = AssetsFolder.Chicken
    Wind.Parent = workspace.Debris
    
    local GroundPos = Functions.GetGroundPos(HitResult.Position)
    Wind.Position = Vector3.new(
        HitResult.Position.X,
        GroundPos.Y + (Wind.Size.Y / 2),
        HitResult.Position.Z
    )
    
    Functions.Emit(Wind)
    Debris:AddItem(Wind, 3)
    
    for _ = 1, 3 do
        local Chicken = ChickenTemplate:Clone()
        Chicken.Parent = workspace.Debris

        local SpawnPos = Vector3.new(
            GroundPos.X + math.random(-3, 3),
            GroundPos.Y - 5,
            GroundPos.Z + math.random(-3, 3)
        )
        local EndPos = Vector3.new(
            GroundPos.X + math.random(-3, 3),
            GroundPos.Y + 2,
            GroundPos.Z + math.random(-3, 3)
        )
        Functions.TweenModel(Chicken, SpawnPos, EndPos, 0.5)
        
        task.delay(1.2, function()
            Functions.Tween(Chicken, {Transparency = 1}, nil, function()
                Chicken:Destroy()
            end)
        end)
    end
end

return Egg