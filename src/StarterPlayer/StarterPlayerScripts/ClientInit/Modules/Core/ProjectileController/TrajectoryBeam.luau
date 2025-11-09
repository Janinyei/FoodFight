--Purpose: Creates a beam that predicts where projectiles will end up based on where players aim
--janin 11/8/25
--note: i hate my life


local TrajectoryBeam = {}

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Constants
local PREDICTION_STEPS = 20
local TIME_STEP = 0.05
local MAX_TIME = 2

-- Variables
local beam = nil
local attachmentContainer = nil
local attachments = {}
local updateConnection = nil
local landingPart = nil

-- Initialize the beam and attachments
function TrajectoryBeam:Init(Core)
    -- Create container part
    attachmentContainer = Instance.new("Part")
    attachmentContainer.Name = "BeamContainer"
    attachmentContainer.Anchored = true
    attachmentContainer.CanCollide = false
    attachmentContainer.CanQuery = false
    attachmentContainer.Transparency = 1
    attachmentContainer.Size = Vector3.one
    attachmentContainer.Parent = workspace
    
    -- Create attachments
    for i = 1, PREDICTION_STEPS do
        local attachment = Instance.new("Attachment")
        attachment.Parent = attachmentContainer
        attachments[i] = attachment
    end
    
    -- Create beam
    beam = Instance.new("Beam")
    beam.Attachment0 = attachments[1]
    beam.Attachment1 = attachments[#attachments]
    beam.CurveSize0 = 0
    beam.CurveSize1 = 0
    beam.FaceCamera = true
    beam.Segments = PREDICTION_STEPS
    beam.Width0 = 0.5
    beam.Width1 = 0.3
    beam.Transparency = NumberSequence.new(0.5)
    beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 100))
    beam.LightEmission = 0.5
    beam.Enabled = false
    beam.Parent = attachmentContainer
    
    -- Create landing indicator
    landingPart = Instance.new("Part")
    landingPart.Name = "LandingIndicator"
    landingPart.Shape = Enum.PartType.Ball
    landingPart.Material = Enum.Material.Neon
    landingPart.Size = Vector3.new(1, 1, 1)
    landingPart.Color = Color3.fromRGB(255, 100, 100)
    landingPart.Transparency = 0.5
    landingPart.Anchored = true
    landingPart.CanCollide = false
    landingPart.CanQuery = false
    landingPart.Parent = workspace
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
function TrajectoryBeam:UpdateBeam(origin, velocity, gravity, raycastParams)
    local points, hitPoint = TrajectoryBeam:CalculatePoints(origin, velocity, gravity, raycastParams)
    
    -- Update attachment positions
    for i, attachment in ipairs(attachments) do
        if points[i] then
            attachment.WorldPosition = points[i]
        end
    end
    
    -- Update landing indicator
    if hitPoint then
        landingPart.Position = hitPoint
        landingPart.Transparency = 0.5
    else
        landingPart.Transparency = 1
    end
end

-- Enable beam and start updating
function TrajectoryBeam:Enable(Data)
    if not beam then
        TrajectoryBeam.Init()
    end
    
    beam.Enabled = true
    
    -- Start update loop
    if updateConnection then
        updateConnection:Disconnect()
    end
    
    updateConnection = RunService.Heartbeat:Connect(function()

        if Data then
            TrajectoryBeam:UpdateBeam(Data.Origin, Data.Velocity, Data.Gravity or Vector3.new(0,-50,0), Data.RaycastParams)
        end
    end)
end

-- Disable beam and stop updating
function TrajectoryBeam:Disable()
    if beam then
        beam.Enabled = false
    end
    
    if landingPart then
        landingPart.Transparency = 1
    end
    
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
end

-- Toggle visibility
function TrajectoryBeam:Toggle(getTrajectoryData)
    if beam and beam.Enabled then
        TrajectoryBeam:Disable()
    else
        TrajectoryBeam:Enable(getTrajectoryData)
    end
end

-- Cleanup
function TrajectoryBeam:Destroy()
    TrajectoryBeam:Disable()
    
    if attachmentContainer then
        attachmentContainer:Destroy()
    end
    
    if landingPart then
        landingPart:Destroy()
    end
    
    beam = nil
    attachmentContainer = nil
    attachments = {}
    landingPart = nil
end

return TrajectoryBeam