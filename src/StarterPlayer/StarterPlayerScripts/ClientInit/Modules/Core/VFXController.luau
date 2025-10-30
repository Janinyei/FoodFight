

local VFXController = {}
local VFXModulesFolder = script.Parent.VisualEffects

function VFXController:Init(Core)
    self.VFXEvent = Core:Get("SharedRemotes"):GetEvent("VFXEvent")
    self.VFXModules = {}


    --caches vfx modules
    for _, module in VFXModulesFolder:GetChildren() do 
         if module:IsA("ModuleScript") then 
            self.VFXModules[module.Name] = Core:Get(module.Name)
         end
    end
end

function VFXController:Start()
    
end

function VFXController:PlayVFX(VFXName : string, data)
    if self.VFXModules[VFXName] then
        self.VFXModules[VFXName]:PlayVFX(data)
        self.VFXEvent:Fire(data)
    end
end

function VFXController:StartReplicationListener()

    self.VFXEvent:Connect(function(data) 
        local Name = data.Name
        print("replicating vfx ".. Name)
    end)
end


return VFXController