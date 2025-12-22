-- Module: Hitbox
-- Purpose: Handles general hitbox detection and validation (Client & Server compatible)
-- Janin 12/18/25

--note: code is mostly generated
--note: I modified some stuff of course

local Hitbox = {}
Hitbox.__index = Hitbox

-- Services
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Constants
local DEBUG_COLOR = Color3.fromRGB(255, 0, 0)
local DEFAULT_LIFETIME = 5

function Hitbox.new()
    local self = setmetatable({}, Hitbox)
    
    -- Configuration
    self.Size = Vector3.new(4, 4, 4) -- Default size
    self.Offset = CFrame.new(0, 0, 0)
    self.Shape = Enum.PartType.Block -- Block, Ball, Cylinder
    self.DetectionMode = "Part" -- "Part" (Instant Detection), "Region" (persistent detection until destroyed)
    
    -- State
    self.Active = false
    self.Owner = nil -- Who owns this hitbox (Player or NPC)
    self.FilterList = {} -- Instances to ignore
    self.HitCooldowns = {} -- [Instance] = tick()
    self.CooldownTime = 0.1 -- How long before the same target can be hit again
    
    -- Raycast specific
    self.RaycastParams = RaycastParams.new()
    self.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    -- Visual Debugging
    self.DebugMode = false
    self.DebugPart = nil
    
    -- Callbacks
    self.OnHit = nil -- Function(hit, humanoid)
    
    -- Internal
    self._connections = {}
    
    return self
end

--------------------------------------------------------------------------------
-- SETUP
--------------------------------------------------------------------------------

function Hitbox:SetOwner(character)
    self.Owner = character
    self:AddToFilter(character)
end

function Hitbox:AddToFilter(instance)
    if typeof(instance) == "Instance" then
        table.insert(self.FilterList, instance)
        self.RaycastParams.FilterDescendantsInstances = self.FilterList
    elseif typeof(instance) == "table" then
        for _, v in ipairs(instance) do
            table.insert(self.FilterList, v)
        end
        self.RaycastParams.FilterDescendantsInstances = self.FilterList
    end
end

--------------------------------------------------------------------------------
-- ACTIVATION
--------------------------------------------------------------------------------

function Hitbox:Start()
    if self.Active then return end
    self.Active = true
    self.HitCooldowns = {} -- Reset cooldowns
    
    if self.DetectionMode == "Part" then
        self:_StartPartDetection()
    elseif self.DetectionMode == "Region" then
        self:_StartRegionDetection()
    end
    
    if self.DebugMode then
        self:_CreateDebugVisual()
    end
end

function Hitbox:Stop()
    self.Active = false
    
    -- Clean up connections
    for _, conn in pairs(self._connections) do
        conn:Disconnect()
    end
    self._connections = {}
    
    if self.DebugPart then
        self.DebugPart:Destroy()
        self.DebugPart = nil
    end
end

--------------------------------------------------------------------------------
-- DETECTION LOGIC
--------------------------------------------------------------------------------

-- 1. Part Touch Detection (Good for projectiles/simple shapes)
function Hitbox:_StartPartDetection()
    -- Create invisible part anchored to CFrame
    local part = Instance.new("Part")
    part.Size = self.Size
    part.CanCollide = false
    part.CanQuery = false -- Don't block raycasts
    part.CanTouch = true
    part.Transparency = 1
    part.Anchored = true
    part.Parent = workspace -- Needs to be in workspace to detect touches
    
    self.DetectionPart = part
    
    -- Update position loop
    local updateConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not self.CFrame then 
            self:Stop()
            return 
        end
        part.CFrame = self.CFrame * self.Offset
    end)
    
    -- Touch event
    local touchConn = part.Touched:Connect(function(hit) --do not use this lolllll
        self:_ProcessHit(hit)
    end)
    
    table.insert(self._connections, updateConn)
    table.insert(self._connections, touchConn)
end

-- 2. Spatial Query Detection (Best for melee/AOE)
function Hitbox:_StartRegionDetection()
    local updateConn = RunService.Heartbeat:Connect(function()
        if not self.Active or not self.CFrame then return end
        
        local cf = self.CFrame * self.Offset
        local overlapParams = OverlapParams.new()
        overlapParams.FilterDescendantsInstances = self.FilterList
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local parts = workspace:GetPartBoundsInBox(cf, self.Size, overlapParams)
        
        for _, part in ipairs(parts) do
            self:_ProcessHit(part)
        end
        
        if self.DebugPart then
            self.DebugPart.CFrame = cf
        end
    end)
    
    table.insert(self._connections, updateConn)
end


--------------------------------------------------------------------------------
-- HIT PROCESSING
--------------------------------------------------------------------------------

function Hitbox:_ProcessHit(hitPart, position, normal)
    if not self.Active then return end
    
    -- Find humanoid/model
    local model = hitPart:FindFirstAncestorOfClass("Model")
    if not model then return end
    
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    if humanoid.Health <= 0 then return end
    
    -- Check cooldown (Debounce)
    local now = tick()
    local lastHit = self.HitCooldowns[model]
    
    if not lastHit or (now - lastHit >= self.CooldownTime) then
        self.HitCooldowns[model] = now
        
        -- Fire callback
        if self.OnHit then
            local hitData = {
                Instance = hitPart,
                Model = model,
                Humanoid = humanoid,
                RootPart = hrp,
                Position = position or hitPart.Position,
                Normal = normal or Vector3.yAxis
            }
            self.OnHit(hitData)
        end
    end
end

--------------------------------------------------------------------------------
-- UTILS
--------------------------------------------------------------------------------

function Hitbox:_CreateDebugVisual()
    local part = Instance.new("Part")
    part.Name = "HitboxDebug"
    part.Size = self.Size
    part.Color = DEBUG_COLOR
    part.Transparency = 0.1
    part.Material = Enum.Material.ForceField
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Anchored = true
    part.Parent = workspace
    self.DebugPart = part
end

function Hitbox:SetCFrame(cf)
    self.CFrame = cf
end

function Hitbox:Destroy()
    self:Stop()
    if self.DetectionPart then
        self.DetectionPart:Destroy()
    end
    self.HitCooldowns = nil
    self.FilterList = nil
    self.OnHit = nil
end

return Hitbox