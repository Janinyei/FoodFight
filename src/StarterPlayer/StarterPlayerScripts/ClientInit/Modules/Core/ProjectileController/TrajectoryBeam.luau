--Purpose: Creates a beam that predicts where projectiles will end up based on where players aim
--Note: replaced with orbs instead js cuz it was easier
--janin 11/8/25
--note: i hate my life


local TrajectoryBeam = {}

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Constants
local PREDICTION_STEPS = 100
local TIME_STEP = 0.05
local MAX_TIME = 2
local BALL_RADIUS = 0.5
local BALL_COLOR = Color3.fromRGB(255, 255, 255)

-- Variables
local loaded = false
local TrajectoryInstanceCache = Instance.new("Folder")
local Parts = {}
local updateConnection = nil
local landingPart = nil

-- Initialize the beam and attachments
function TrajectoryBeam:Init(Core)


    TrajectoryInstanceCache.Parent = workspace
    TrajectoryInstanceCache.Name = "TrajectoryInstanceCache"

    -- Create orbs
    for i = 1, PREDICTION_STEPS do
        local Ball = Instance.new("Part")
        Ball.Size = Vector3.one * BALL_RADIUS
        Ball.Shape = Enum.PartType.Ball
        Ball.Name = "TrajectoryBall"
        Ball.Parent = TrajectoryInstanceCache
        Ball.Material = Enum.Material.Neon
        Ball.Transparency = 0.3
        Ball.Anchored  = true
        Ball.CanCollide = false
        Ball.CanTouch = false
        Ball.CanQuery = false -- makes sure there's no raycast interference
        Ball.Color = BALL_COLOR
        
        Parts[i] = Ball
    end

    
    -- Create landing indicator
    landingPart = Instance.new("Part")
    landingPart.Name = "LandingIndicator"
    landingPart.Shape = Enum.PartType.Ball
    landingPart.Material = Enum.Material.ForceField
    landingPart.Size = Vector3.new(5, 5, 5)
    landingPart.Color = Color3.fromRGB(255, 255, 255)
    landingPart.Transparency = 0
    landingPart.Anchored = true
    landingPart.CanCollide = false
    landingPart.CanQuery = false
    landingPart.Parent = TrajectoryInstanceCache
    

    loaded = true --prevents duplicate parts
end

-- Calculate trajectory points
function TrajectoryBeam:CalculatePoints(origin, velocity, gravity, raycastParams)
    local points = {}
    local currentPos = origin
    local currentVel = velocity
    local hitPoint = nil
    
    for i = 1, PREDICTION_STEPS do
        points[i] = currentPos
        
        -- Update velocity and position
        currentVel = currentVel + gravity * TIME_STEP
        local nextPos = currentPos + currentVel * TIME_STEP
        
        -- Check for hit
        local rayResult = workspace:Raycast(currentPos, nextPos - currentPos, raycastParams)
        if rayResult then
            hitPoint = rayResult.Position
            points[i] = hitPoint
            -- Fill remaining points with hit position
            for j = i + 1, PREDICTION_STEPS do
                points[j] = hitPoint
            end
            break
        end
        
        
        currentPos = nextPos
        
        -- Stop if too low
        if currentPos.Y < -500 then
            break
        end
    end
    
    return points, hitPoint
end

-- Update beam visual
function TrajectoryBeam:UpdateBeam(origin, velocity, gravity, raycastParams, dt)
    local points, hitPoint = TrajectoryBeam:CalculatePoints(origin, velocity, gravity, raycastParams, dt)
    
    -- Update attachment positions
    for i, orb in ipairs(Parts) do
        if points[i] then
            orb.Position = points[i]
            if orb.Transparency == 1 then
                orb.Transparency = 0
            end
        end
    end
    
    -- Update landing indicator
    if hitPoint then
        landingPart.Position = hitPoint
        landingPart.Transparency = 0
    else
        landingPart.Transparency = 1
    end
end

-- Enable beam and start updating
function TrajectoryBeam:Enable(getTrajectoryData)

    if not loaded then
        self:Init()
    end

    -- Start update loop
    if updateConnection then
        updateConnection:Disconnect()
    end

    
    
    updateConnection = RunService.Heartbeat:Connect(function()
        local Data = getTrajectoryData() --updates info every frame and stuff

        if Data then
            TrajectoryBeam:UpdateBeam(Data.Origin, Data.Velocity, Data.Gravity or Vector3.new(0,-50,0), Data.RaycastParams)
        end
    end)


    
    --idk
    
    
    
end

-- Disable beam and stop updating
function TrajectoryBeam:Disable()
    if landingPart then
        landingPart.Transparency = 1
    end

    for _, orb in Parts do
        orb.Transparency = 1
    end

    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
end



return TrajectoryBeam