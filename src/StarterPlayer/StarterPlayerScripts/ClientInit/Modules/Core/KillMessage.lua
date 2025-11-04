-- Purpose: Shows kill messages when a player is killed
-- Displays "DESTROYED [PlayerName] +100 Coins" format

local Players = game:GetService("Players")
local AnimNation = require(game.ReplicatedStorage.Modules.Utils.AnimNation)

local KillMessage = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DEFAULT_COIN_REWARD = 100
local DEFAULT_EXP_REWARD = 100

local MessageQueue = {}
local CurrentZIndex = 0

local function CreateKillMessage(targetName, coins, exp)
	CurrentZIndex = CurrentZIndex - 1

	local container = Instance.new("Frame")
	container.Name = "KillMessage"
	container.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.Size = UDim2.new(0, 0, 0, 60)
	container.AutomaticSize = Enum.AutomaticSize.X
	container.Position = UDim2.new(0.5, 0, 0.3, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.ZIndex = CurrentZIndex
	container.Parent = PlayerGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = container

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.new(0.2, 0.2, 0.2)
	uiStroke.Thickness = 2
	uiStroke.Parent = container

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.Parent = container

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "Coins"
	coinsLabel.Size = UDim2.new(0, 0, 1, 0)
	coinsLabel.AutomaticSize = Enum.AutomaticSize.X
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "+" .. tostring(coins)
	coinsLabel.TextColor3 = Color3.new(1, 0.84, 0)
	coinsLabel.TextSize = 24
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.Parent = container

	local coinsStroke = Instance.new("UIStroke")
	coinsStroke.Color = Color3.new(0, 0, 0)
	coinsStroke.Thickness = 2
	coinsStroke.Parent = coinsLabel

	local destroyedLabel = Instance.new("TextLabel")
	destroyedLabel.Name = "Destroyed"
	destroyedLabel.Size = UDim2.new(0, 0, 1, 0)
	destroyedLabel.AutomaticSize = Enum.AutomaticSize.X
	destroyedLabel.BackgroundTransparency = 1
	destroyedLabel.Text = "DESTROYED"
	destroyedLabel.TextColor3 = Color3.new(1, 1, 1)
	destroyedLabel.TextSize = 24
	destroyedLabel.Font = Enum.Font.GothamBold
	destroyedLabel.Parent = container

	local destroyedStroke = Instance.new("UIStroke")
	destroyedStroke.Color = Color3.new(0, 0, 0)
	destroyedStroke.Thickness = 2
	destroyedStroke.Parent = destroyedLabel

	local playerLabel = Instance.new("TextLabel")
	playerLabel.Name = "Player"
	playerLabel.Size = UDim2.new(0, 0, 1, 0)
	playerLabel.AutomaticSize = Enum.AutomaticSize.X
	playerLabel.BackgroundTransparency = 1
	playerLabel.Text = string.upper(targetName or "UNKNOWN")
	playerLabel.TextColor3 = Color3.new(1, 0, 0) -- Red
	playerLabel.TextSize = 24
	playerLabel.Font = Enum.Font.GothamBold
	playerLabel.Parent = container

	local playerStroke = Instance.new("UIStroke")
	playerStroke.Color = Color3.new(0, 0, 0)
	playerStroke.Thickness = 2
	playerStroke.Parent = playerLabel

	return container
end

function KillMessage:ShowKill(targetName, coins, exp)
	coins = coins or DEFAULT_COIN_REWARD
	exp = exp or DEFAULT_EXP_REWARD

	local message = CreateKillMessage(targetName, coins, exp)
	message.Position = UDim2.new(0.5, 0, 0.25, 0)
	message.Size = UDim2.new(0, 0, 0, 60)
	
	task.wait()
	local targetWidth = message.AbsoluteSize.X
	if targetWidth == 0 then
		targetWidth = 400
	end
	
	AnimNation.tween(message, {
		t = 0.3,
		s = Enum.EasingStyle.Quad,
		d = Enum.EasingDirection.Out
	}, {
		Size = UDim2.new(0, targetWidth, 0, 60)
	}):Await()

	task.wait(2)
	AnimNation.tween(message, {
		t = 0.3,
		s = Enum.EasingStyle.Quad,
		d = Enum.EasingDirection.In
	}, {
		Size = UDim2.new(0, 0, 0, 60),
		BackgroundTransparency = 1
	}):AndThen(function()
		if message.Parent then
			message:Destroy()
		end
	end)
	for _, child in ipairs(message:GetChildren()) do
		if child:IsA("TextLabel") then
			AnimNation.tween(child, {
				t = 0.3,
				s = Enum.EasingStyle.Quad,
				d = Enum.EasingDirection.In
			}, {
				TextTransparency = 1
			})
		end
	end
end

return KillMessage

