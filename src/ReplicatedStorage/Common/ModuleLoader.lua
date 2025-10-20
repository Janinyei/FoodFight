--10/19/25 janin & tzu module loader
local module = {}
module.CachedModules = {}


for _,v in pairs(script.Parent.Modules:Descendants()) do
    if v:IsA("ModuleScript") then
        module.CachedModules[v.Name] = require(v)
    end
    require(v)
end

return module