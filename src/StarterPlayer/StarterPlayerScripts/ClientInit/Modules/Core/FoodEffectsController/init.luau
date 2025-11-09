-- Purpose: Game specific bridge for food effects and vfx management
--janin 11/8/25

local FoodEffectsController = {}
local FoodModules = {}

function FoodEffectsController:Init(Core)
    self.Core = Core
    self.VFXController = Core:Get("VFXController")
    self.VFXEvent = Core:Get("SharedRemotes"):GetEvent("VFXEvent")
    self.CommonEffects = script.Parent.VisualEffects.CommonEffects
end


function FoodEffectsController:Start()
    -- Load all food modules
    self:LoadFoodModules()
    -- Register common food effects with VFXController
    self:RegisterCommonEffects()
end

function FoodEffectsController:LoadFoodModules()
    local foodModulesFolder = script.FoodModules
    for _, module in pairs(foodModulesFolder:GetChildren()) do
        if module:IsA("ModuleScript") then
            local foodModule = require(module)
            FoodModules[module.Name] = foodModule
        end
    end
end

function FoodEffectsController:RegisterCommonEffects()
    -- Register reusable food effects
    local TargetFolder = self.CommonEffects
    self.VFXController:RegisterEffect("FoodSplat", require(TargetFolder.FoodSplat))  
end


function FoodEffectsController:OnHit(vfxData)

    print("processing food vfx for: ".. vfxData.Name)
    local foodModule = FoodModules[vfxData.Name]
    
    if foodModule and foodModule.OnHit then
        -- Let the food module handle its own vfx hit logic
        foodModule:OnHit(vfxData, self.VFXController)
    else
        -- Fallback to generic food hit effect
        self.VFXController:PlayEffect("FoodSplat", {
            Position = vfxData.Position,
        })
    end
    
    -- Replicate if needed
    self.VFXEvent:Fire(true, vfxData)
end

return FoodEffectsController