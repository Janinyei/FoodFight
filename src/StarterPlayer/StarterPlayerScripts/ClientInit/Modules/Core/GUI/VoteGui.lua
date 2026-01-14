local VoteGui = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- Utils
local Spring = require(game.ReplicatedStorage.Modules.Utils.Spring)

-- Variables
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

function VoteGui:Init(Core)
    self.SharedRemotes = Core:Get("SharedRemotes")
    self.MouseController = Core:Get("MouseController")

    self.VoteGui = PlayerGui:WaitForChild("Voting")
    self.VoteEvent = self.SharedRemotes:GetEvent("VoteEvent")

    self.isVoting = false
    self.PlayerHeadshotTemplate = self.VoteGui.Container.templates.PlayerHeadshot

    -- Tracking tables using unique keys (UserId_VoteType)
    self.Headshots = {}        -- [UniqueKey] = Frame
    self.IconSprings = {}      -- [UniqueKey] = SpringObject
    self.SpringConnections = {} -- [UniqueKey] = RBXScriptConnection
end

function VoteGui:Start()
    self.VoteEvent:Connect(function(action, data)
        if action == "Enable" then
            self.VoteGui.Enabled = true
            self.isVoting = true
            self:_loadVoteGui(data)
        elseif action == "Disable" then
            self.VoteGui.Enabled = false
            self.isVoting = false
            self:_Cleanup()
        elseif action == "UpdateHeadshot" then
            self:_updateHeadshot(data)
        end
    end)

    -- Close button logic
    local exitBtn = self.VoteGui.Container.Folder.ExitButton.Button
    exitBtn.MouseButton1Click:Connect(function()
        self.VoteGui.Enabled = false
    end)

    -- Initialize click listeners for all voting buttons
    for _, votingSection in self.VoteGui.Container:GetChildren() do
        if votingSection:IsA("Frame") then
            for _, optionFrame in votingSection:GetChildren() do
                if optionFrame:IsA("Frame") then
                    local voteType = votingSection.Name -- e.g., "Maps"
                    local voteIndex = optionFrame.Name  -- e.g., "1"

                    optionFrame.ImageButton.MouseButton1Click:Connect(function()
                        local mouseLocation = UIS:GetMouseLocation()
                        local button = optionFrame.ImageButton
                        local guiInset = GuiService:GetGuiInset()

                        -- Calculate position relative to the button
                        local mouseX = mouseLocation.X - button.AbsolutePosition.X
                        local mouseY = (mouseLocation.Y - guiInset.Y) - button.AbsolutePosition.Y
                        
                        -- Convert to Scale (0 to 1) for cross-device consistency
                        local scaleX = math.clamp(mouseX / button.AbsoluteSize.X, 0, 1)
                        local scaleY = math.clamp(mouseY / button.AbsoluteSize.Y, 0, 1)

                        self.VoteEvent:Fire(true, {
                            voteType = voteType,
                            voteIndex = voteIndex,
                            Position = {X = scaleX, Y = scaleY},
                        })

                        -- Local visual feedback (Selection Stroke)
                        self:_updateSelectionStroke(votingSection, optionFrame)
                    end)
                end
            end
        end
    end
end

-- Sets the stroke of the selected option to white and others to black
function VoteGui:_updateSelectionStroke(section, selectedFrame)
    for _, frame in section:GetChildren() do
        if frame:IsA("Frame") and frame:FindFirstChild("UIStroke") then
            frame.UIStroke.Color = (frame == selectedFrame) 
                and Color3.fromRGB(255, 255, 255) 
                or Color3.fromRGB(0, 0, 0)
        end
    end
end

-- Loads text labels for Maps and Modes
function VoteGui:_loadVoteGui(optionData)
    for voteType, optionList in pairs(optionData) do
        for index, optionName in pairs(optionList) do
            local targetOptionFrame = self.VoteGui.Container[voteType]:FindFirstChild(tostring(index))
            if targetOptionFrame and targetOptionFrame:FindFirstChild("TextLabel") then
                targetOptionFrame.TextLabel.Text = optionName
            end
        end
    end
end

-- Main logic for moving/creating bouncy headshots
function VoteGui:_updateHeadshot(data)
    local targetPlr = data.Player
    local voteType = data.voteType
    local optionIndex = tostring(data.OptionIndex)
    
    -- uniqueKey allows one icon for Maps and one for Modes per player
    local uniqueKey = targetPlr.UserId .. "_" .. voteType
    local targetContainer = self.VoteGui.Container[voteType][optionIndex].ImageButton

    local profileFrame = self.Headshots[uniqueKey]
    local spring = self.IconSprings[uniqueKey]

    -- Convert the received scale back to pixels relative to the local user's button size
    local function getTargetOffset()
        return Vector2.new(
            data.Position.X * targetContainer.AbsoluteSize.X,
            data.Position.Y * targetContainer.AbsoluteSize.Y
        )
    end

    local relativePos = getTargetOffset()

    if not profileFrame then
        -- 1. Create Profile UI
        profileFrame = self.PlayerHeadshotTemplate:Clone()
        profileFrame.Name = uniqueKey
        profileFrame.AnchorPoint = Vector2.new(0.5, 0.5) -- Center icon on click point
        profileFrame.Visible = true

        -- 2. Fetch Thumbnail
        task.spawn(function()
            local content = Players:GetUserThumbnailAsync(
                targetPlr.UserId, 
                Enum.ThumbnailType.HeadShot, 
                Enum.ThumbnailSize.Size48x48
            )
            if profileFrame:FindFirstChild("Container") then
                profileFrame.Container.ImageLabel.Image = content
            end
        end)

        -- 3. Setup Spring
        spring = Spring.new(relativePos)
        spring.Damper = 0.8 -- Bouncy feel
        spring.Speed = 15
        
        self.Headshots[uniqueKey] = profileFrame
        self.IconSprings[uniqueKey] = spring

        -- 4. Start Update Loop (Necessary for lazy springs)
        self.SpringConnections[uniqueKey] = RunService.RenderStepped:Connect(function()
            local currentPos = spring.Position
            profileFrame.Position = UDim2.fromOffset(currentPos.X, currentPos.Y)
        end)
    end

    -- Update parent and target
    profileFrame.Parent = targetContainer
    spring.Target = relativePos
    
    -- Subtle physics punch
    spring:Impulse(Vector2.new(0, 10)) 
end

function VoteGui:_Cleanup()
    -- Reset all strokes to black
    for _, section in self.VoteGui.Container:GetChildren() do
        if section:IsA("Frame") then
            for _, frame in section:GetChildren() do
                if frame:IsA("Frame") and frame:FindFirstChild("UIStroke") then
                    frame.UIStroke.Color = Color3.fromRGB(0, 0, 0)
                end
            end
        end
    end

    -- Disconnect all spring loops
    for key, connection in pairs(self.SpringConnections) do
        connection:Disconnect()
    end

    -- Destroy all headshot icons
    for key, frame in pairs(self.Headshots) do
        frame:Destroy()
    end

    -- Wipe tables
    self.Headshots = {}
    self.IconSprings = {}
    self.SpringConnections = {}
end

return VoteGui