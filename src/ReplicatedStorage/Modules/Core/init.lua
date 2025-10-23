local RunService = game:GetService("RunService")

local Core = {}
Core._modules = {}
Core._initialized = false
Core._started = false

-- Direct access to modules is more efficient than using a metatable
-- Gets the module called
function Core:Get(moduleName : string)
    local module = self._modules[moduleName]
    if not module then
        error(("Module '%s' not found."):format(moduleName))
    end
    return module
end


--Purpose: To load and initialize modules
function Core:Init(ModulesToLoad : Folder)
    if self._initialized then
        warn("[Core] Already initialized")
        return
    end

    --load shared modules first
    local SharedModulesFolder = script.SharedModules
    if SharedModulesFolder then
        for _, module : ModuleScript in SharedModulesFolder:GetDescendants() do
            if module:IsA("ModuleScript") then
                self._modules[module.Name] = require(module)
            end
        end
    end

    local ModuleFolder = ModulesToLoad
    if ModuleFolder then
       for _, module : ModuleScript in ModuleFolder:GetDescendants() do
        if module:IsA("ModuleScript") then
            self._modules[module.Name] = require(module)
        end
    end
     
    
    -- Initialize modules. Checks if module actually has an init function first, then runs it
    for name, module in pairs(self._modules) do
        if type(module) == "table" and module.Init then --checks if the module is a table. This is especially useful just incase we have modules that simply return functions.
            local success, err = pcall(module.Init, module, self) --wrapped in pcall just in case it errors
            if not success then
                warn("[Core] Error initializing module:", name, err)
            end
        end
    end
    
    self._initialized = true
end
end


function Core:Start()
    if not self._initialized then
        warn("[Core] Must call Init() before Start()")
        return
    end
    
    if self._started then
        return
    end
    
    -- Start modules
    for name, module in pairs(self._modules) do
        if type(module) == "table" and module.Start then
            task.spawn(function()
                local success, err = pcall(module.Start, module, self)
                if not success then
                    warn("[Core] Error starting module:", name, err)
                end
            end)
        end
    end
    
    self._started = true
end

return Core