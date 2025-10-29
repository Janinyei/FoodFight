local GuiLoaderManager = {}
--high priority

--Services--
local StarterGui = game:GetService("StarterGui")

function GuiLoaderManager:Init()
   

    self.CacheFolder = game.ReplicatedStorage.UICache
end

function GuiLoaderManager:Start()
    for _, ScreenGui in StarterGui:GetChildren() do
        if ScreenGui:IsA("ScreenGui") then
            ScreenGui.Parent = self.CacheFolder
        end
    end
end




return GuiLoaderManager