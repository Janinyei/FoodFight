-- WIP
local KOHGui = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

-- Modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeamConfig = require(ReplicatedStorage.Modules.Info.TeamConfig)

function KOHGui:Init(Core)
	self.SharedRemotes = Core:Get("SharedRemotes")
	self.KOHUpdate = self.SharedRemotes:GetEvent("KOHUpdate")
	self.GameEvent = self.SharedRemotes:GetEvent("GameEvent")

	self.HUD = PlayerGui:WaitForChild("HUD")
	self.Container = self.HUD:FindFirstChild("KOH_Container") or self:CreateUI()
	self.Container.Visible = false
end

local function IsInPart(point, part)
	local relative = part.CFrame:PointToObjectSpace(point)
	return math.abs(relative.X) <= part.Size.X/2
		and math.abs(relative.Y) <= part.Size.Y/2
		and math.abs(relative.Z) <= part.Size.Z/2
end

function KOHGui:Start()
	self.KOHUpdate:Connect(function(data)
		self.Container.Visible = true
		self:Update(data)
	end)

	self.GameEvent:Connect(function(_inGame, gameData)
		if not _inGame or (gameData and gameData.CurrentMode ~= "KOH") then
			self.Container.Visible = false
		end
	end)                                        
end

function KOHGui:CreateUI()
	local container = Instance.new("Frame")
	container.Name = "KOH_Container"
	container.Size = UDim2.fromScale(0.3, 0.05)
	container.Position = UDim2.fromScale(0.5, 0.05)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundTransparency = 1
	container.Parent = self.HUD

	local barBg = Instance.new("Frame")
	barBg.Name = "ProgressBarBase"
	barBg.Size = UDim2.fromScale(1, 1)
	barBg.Position = UDim2.fromScale(0.5, 0.5)
	barBg.AnchorPoint = Vector2.new(0.5, 0.5)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	barBg.BorderSizePixel = 0
	barBg.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.BackgroundColor3 = Color3.new(1, 1, 1)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = barFill

	local statusText = Instance.new("TextLabel")
	statusText.Name = "Status"
	statusText.Size = UDim2.fromScale(1, 1)
	statusText.BackgroundTransparency = 1
	statusText.Text = "NEUTRAL"
	statusText.TextColor3 = Color3.new(1, 1, 1)
	statusText.Font = Enum.Font.GothamMedium
	statusText.TextSize = 14
	statusText.Parent = barBg

	self.BarFill = barFill
	self.StatusText = statusText
	
	return container
end

function KOHGui:Update(data)
	local hills = data.Hills
	if not hills or #hills == 0 then return end
	
	local bestHill = hills[1]
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	
	if root then
		local pos = root.Position
		for _, hill in ipairs(hills) do
			local zone = workspace:FindFirstChild(hill.Id, true)
			if zone and zone:IsA("BasePart") and IsInPart(pos, zone) then
				bestHill = hill
				break
			end
		end
		
		if bestHill == hills[1] then
			for _, hill in ipairs(hills) do
				if hill.IsContested or (hill.Progress > 0 and hill.Progress < 1) then
					bestHill = hill
					break
				end
			end
		end
	end

	local hill = bestHill
	local targetColor = Color3.fromRGB(150, 150, 150)
	local status = "NEUTRAL"
	
	if hill.Owner then
		targetColor = TeamConfig[hill.Owner or "neutral"].Color or targetColor
		status = hill.Id:upper() .. ": CONTROLLED BY " .. (hill.Owner:upper())
	elseif hill.CapturingTeam then
		targetColor = TeamConfig[hill.CapturingTeam or "neutral"].Color or targetColor
		status = hill.Id:upper() .. ": CAPTURING... (" .. math.floor(hill.Progress * 100) .. "%)"
	end
	
	if hill.IsContested then
		status = hill.Id:upper() .. ": CONTESTED!"
	end

	self.StatusText.Text = status
	
	TweenService:Create(self.BarFill, TweenInfo.new(0.3), {
		Size = UDim2.fromScale(hill.Progress, 1),
		BackgroundColor3 = targetColor
	}):Play()
end

return KOHGui
