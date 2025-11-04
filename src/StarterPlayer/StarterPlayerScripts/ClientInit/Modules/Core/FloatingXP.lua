local Players = game:GetService("Players")
local AnimNation = require(game.ReplicatedStorage.Modules.Utils.AnimNation)

local FloatingXP = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DEFAULT_EXP_REWARD = 100

local function GetExpElements()
	local menu = PlayerGui:FindFirstChild("Menu")
	if not menu then return nil, nil end

	local container = menu:FindFirstChild("Container")
	if not container then return nil, nil end

	local progressionFrame = container:FindFirstChild("ProgressionFrame")
	if not progressionFrame then return nil, nil end

	local progressBarContainer = progressionFrame:FindFirstChild("ProgressBarContainer")
	if not progressBarContainer then return nil, nil end

	local expLabel = progressBarContainer:FindFirstChild("ExpAmount")
	if not expLabel then return nil, nil end

	return expLabel, progressionFrame
end

function FloatingXP:ShowXP(amount)
	amount = amount or DEFAULT_EXP_REWARD

	local expLabel, progressionFrame = GetExpElements()
	if not expLabel or not progressionFrame then
		warn("ExpAmount label or ProgressionFrame not found")
		return
	end

	local expAbsolutePos = expLabel.AbsolutePosition
	local expAbsoluteSize = expLabel.AbsoluteSize
	
	local frameAbsolutePos = progressionFrame.AbsolutePosition
	local frameAbsoluteSize = progressionFrame.AbsoluteSize
	
	local xOffset = (expAbsolutePos.X + expAbsoluteSize.X / 2) - frameAbsolutePos.X
	local yOffset = (expAbsolutePos.Y + expAbsoluteSize.Y) - frameAbsolutePos.Y + 5
	
	local xScale = xOffset / frameAbsoluteSize.X
	local yOffsetScale = yOffset / frameAbsoluteSize.Y

	local floatingText = Instance.new("TextLabel")
	floatingText.Name = "FloatingXP"
	floatingText.Size = UDim2.fromOffset(0, 30)
	floatingText.AutomaticSize = Enum.AutomaticSize.X
	floatingText.Position = UDim2.new(xScale, 0, yOffsetScale, 0)
	floatingText.AnchorPoint = Vector2.new(0.5, 0)
	floatingText.BackgroundTransparency = 1
	floatingText.Text = "+" .. tostring(amount)
	floatingText.TextColor3 = Color3.new(1, 1, 1)
	floatingText.TextSize = 18
	floatingText.Font = Enum.Font.GothamBold
	floatingText.ZIndex = expLabel.ZIndex + 10
	floatingText.Parent = progressionFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 2
	stroke.Parent = floatingText

	local endYOffset = yOffsetScale + 0.1
	local endPosition = UDim2.new(xScale, 0, endYOffset, 0)

	AnimNation.tween(floatingText, {
		t = 1,
		s = Enum.EasingStyle.Quad,
		d = Enum.EasingDirection.Out
	}, {
		Position = endPosition,
		TextTransparency = 1
	}):AndThen(function()
		if floatingText.Parent then
			floatingText:Destroy()
		end
	end)
	AnimNation.tween(stroke, {
		t = 1,
		s = Enum.EasingStyle.Quad,
		d = Enum.EasingDirection.Out
	}, {
		Transparency = 1
	})
end

return FloatingXP

