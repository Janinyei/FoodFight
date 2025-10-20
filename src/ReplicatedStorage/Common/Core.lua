local RunService = game:GetService("RunService")

local Core = {}
Core._modules = {}
Core._initialized = false
Core._started = false

Core.Modules = setmetatable({}, {
    __index = function(_, key)
        local module = Core._modules[key]
        if not module then
            error(("Module '%s' not found."):format(key))
        end
        return module
    end
})

local function findModules(parent, modules)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("ModuleScript") then
            local success, module = pcall(require, child)
            if success then
                modules[child.Name] = module
                print("[Core] Loaded module:", child.Name)
            else
                warn("[Core] Failed to require module:", child.Name, module)
            end
        end
        
        if child:IsA("Folder") then
            findModules(child, modules)
        end
    end
end

function Core:Init()
    if self._initialized then
        warn("[Core] Already initialized")
        return
    end
    
    if RunService:IsServer() then
        local ServerScriptService = game:GetService("ServerScriptService")
        if ServerScriptService:FindFirstChild("Modules") then
            findModules(ServerScriptService.Modules, self._modules)
        end
    else
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        
        if LocalPlayer:FindFirstChild("PlayerScripts") then
            local playerScripts = LocalPlayer.PlayerScripts
            if playerScripts:FindFirstChild("Modules") then
                findModules(playerScripts.Modules, self._modules)
            end
        end
    end
    
    for name, module in pairs(self._modules) do
        if type(module) == "table" and module.Init then
            local success, err = pcall(module.Init, module, self.Modules)
            if not success then
                warn("[Core] Error initializing module:", name, err)
            end
        end
    end
    
    self._initialized = true
end

function Core:Start()
    if not self._initialized then
        warn("[Core] Must call Init() before Start()")
        return
    end
    
    if self._started then
        return
    end
    
    for name, module in pairs(self._modules) do
        if type(module) == "table" and module.Start then
            task.spawn(function()
                local success, err = pcall(module.Start, module, self.Modules)
                if not success then
                    warn("[Core] Error starting module:", name, err)
                end
            end)
        end
    end
    
    self._started = true
end

return Core