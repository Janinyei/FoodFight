

local VFXController = {}
local FoodClientModulesFolder = script.Parent.FoodClientModules

function VFXController:Init(Core)
    self.VFXEvent = Core:Get("SharedRemotes"):GetEvent("VFXEvent")
    self.FoodClientModules = {}
    
    for _, module in FoodClientModulesFolder:GetChildren() do
        if module:IsA("ModuleScript") then
            local foodModule = require(module)
            self.FoodClientModules[module.Name] = foodModule
        end
    end
end

function VFXController:Start()
    self:StartReplicationListener() --start the replication listener
end

function VFXController:PlayVFX(data)
    local FoodName = data.FoodName
    if FoodName and self.FoodClientModules[FoodName] then
        local foodModule = self.FoodClientModules[FoodName]
        
        local hitResult = {
            Position = data.Position,
            Normal = data.Normal or Vector3.new(0, 1, 0),
            Instance = data.Instance
        }
        
        if foodModule.OnHit then
            foodModule:OnHit(nil, hitResult)
        end
        
        local replicationData = {
            FoodName = FoodName,
            Position = data.Position,
            Normal = data.Normal or Vector3.new(0, 1, 0)
        }
        
        -- replicate to server
        self.VFXEvent:Fire(true, replicationData)
    end
end

function VFXController:StartReplicationListener()
    self.VFXEvent:Connect(function(data) 
        if data.Name and not data.FoodName then
            data.FoodName = data.Name
        end
        print("replicating vfx ".. (data.FoodName or "unknown"))
        self:PlayVFX(data)
    end)
end


return VFXController