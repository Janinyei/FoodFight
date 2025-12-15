--Purpose: Manages collision groups 

--Services--
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local CollisionGroupManager = {}


function CollisionGroupManager:Start()
    PhysicsService:CollisionGroupSetCollidable("Noclip", "Noclip", false)    

    Players.PlayerAdded:Connect(function(player)
     player.CharacterAdded:Connect(function(char) 
       self:NoclipModel(char)
     end)
    end)
end

function CollisionGroupManager:NoclipModel(Model : Model)
    for _, obj in Model:GetDescendants() do
               local success, err = pcall(function()
                 local prop = obj.CollisionGroup
               end)
    
               if success then
                   obj.CollisionGroup = "Noclip"
               
               end
     end
end



return CollisionGroupManager