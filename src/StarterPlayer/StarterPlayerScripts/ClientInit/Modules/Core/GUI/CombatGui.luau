--Purpose: Displays and adjusts combat-related gui, such as hitmarkers, damage indicators,
--janin 11/15/25

--bro i'm tired of working on ts

local CombatGui = {}
--Services--
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--Modules--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils

local AnimNation = require(Utils.AnimNation)
local Functions = require(Utils.Functions)
local Signal = require(Utils.Signal)

--Variables--
local Assets = ReplicatedStorage.Assets

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local BillboardGuis = {}
local ActiveDamageLabels = {}

--Constants--
local COMBAT_FEEDBACK_LIFETIME = 3

--Gui

function CombatGui:Init(Core)
	self.ProjectileController = Core:Get("ProjectileController")
	self.HUD = PlayerGui.HUD
	self.FoodCombatController = Core:Get("FoodCombatController")


	
	
end

function CombatGui:Start()
	--Signals--
	
	self.DamageDealt = self.FoodCombatController.DamageDealt
	self.DamageReceived = self.FoodCombatController.DamageReceived
	self.PlayerEliminated = nil --maybe lol

	self.DamageDealt:Connect(function(data)
		print(data)

		self:ShowDamageIndicator(data.TargetCharacter, data.Amount)
		self:ShowHitmarker(0.35)

		if data.TargetPlayer then
		self:FeedbackMessage(data.TargetPlayer, "Elimination!", 100)
		end
	end)

	self.DamageReceived:Connect(function(data)
		print(data)
	end)
	
end

--gets combat billboard
local function GetBillboardForCharacter(TargetCharacter)
	if BillboardGuis[TargetCharacter] then
		return BillboardGuis[TargetCharacter] --returns if already exists
	end

	local Head = TargetCharacter:FindFirstChild("Head") or TargetCharacter:FindFirstChild("HumanoidRootPart")
	if not Head then
		return nil
	end

	local Billboard = Instance.new("BillboardGui")
	Billboard.Name = "DamageNumbers_" .. TargetCharacter.Name
	Billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Billboard.AlwaysOnTop = true
	Billboard.ResetOnSpawn = false
	Billboard.ClipsDescendants = false
	Billboard.Size = UDim2.fromScale(1.75, 1.75)
	Billboard.StudsOffset = Vector3.new(0, 3, 0)
	Billboard.Adornee = Head
	Billboard.Parent = PlayerGui

	BillboardGuis[TargetCharacter] = Billboard

	TargetCharacter.Destroying:Connect(function()
		Billboard:Destroy()
		BillboardGuis[TargetCharacter] = nil
	end)
	return Billboard
end

function CombatGui:ShowDamageIndicator(TargetCharacter, Damage, Color)
	if not TargetCharacter or not TargetCharacter.Parent then
		return
	end

	local Billboard = GetBillboardForCharacter(TargetCharacter)
	if not Billboard then
		return
	end

	local CurrentTime = os.clock()
	local ActiveLabel = ActiveDamageLabels[TargetCharacter]

	if ActiveLabel and CurrentTime - ActiveLabel.StartTime < 0.75 then
		ActiveLabel.StartTime = CurrentTime
		local CombinedAmount = ActiveLabel.Amount + Damage
		--local MaxDamage = math.min(CombinedAmount, 100)
		ActiveLabel.Amount = math.round(CombinedAmount)
		ActiveLabel.Label.Number.Text = tostring(ActiveLabel.Amount)

		ActiveLabel.Label.Number.TextTransparency = 0
		if ActiveLabel.Label.Number:FindFirstChild("UIStroke") then
			ActiveLabel.Label.Number.UIStroke.Transparency = 0
		end

		ActiveLabel.FadeStartTime = CurrentTime

		AnimNation.target(ActiveLabel.Label.Number, {
			s = 30,
			d = 1,
		}, {
			TextColor3 = Color or Color3.new(1, 1, 1),
		})
	else
		local Label = Assets.UI.DamageNumber:Clone()
		Label.Parent = Billboard
		ActiveLabel = {
			StartTime = CurrentTime,
			Amount = Damage,
			Label = Label,
			FadeStartTime = CurrentTime,
		}
		ActiveDamageLabels[TargetCharacter] = ActiveLabel
		ActiveLabel.Label.Number.Text = tostring(ActiveLabel.Amount)
		ActiveLabel.Label.Number.TextColor3 = Color or Color3.new(1, 1, 1)

		task.spawn(function()
			while ActiveLabel and ActiveLabel.Label and ActiveLabel.Label.Parent do
				local Elapsed = os.clock() - ActiveLabel.FadeStartTime
				if Elapsed >= 0.75 then
					break
				end

				local Alpha = Elapsed / 0.75
				ActiveLabel.Label.Number.TextTransparency = Alpha
				if ActiveLabel.Label.Number:FindFirstChild("UIStroke") then
					ActiveLabel.Label.Number.UIStroke.Transparency = Alpha
				end
				task.wait()
			end

			if ActiveLabel and ActiveLabel.Label then
				ActiveLabel.Label:Destroy()
			end
			if ActiveDamageLabels[TargetCharacter] == ActiveLabel then
				ActiveDamageLabels[TargetCharacter] = nil
			end
		end)
	end

	if ActiveLabel and ActiveLabel.Label then
		AnimNation.impulse(ActiveLabel.Label.Number, {
			s = 30,
			d = 0.6,
		}, {
			Size = UDim2.fromScale(1, 1.5),
		})
	end
end



--displays hitmarker temporarily
function CombatGui:ShowHitmarker(Duration: number)

	--[[print("tween hitmarker")
	local HitmarkerTween = Functions.Tween(
		Hitmarker,
		{
			ImageTransparency = 0,
		},
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		function()
			task.delay(Duration, function()
				Functions.Tween(Hitmarker, {
					ImageTransparency = 1,
				}, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
			end)
		end
	)
	]]


	local Crosshair = self.HUD.Crosshair
	local Hitmarker = Crosshair.Hitmarker

	AnimNation.target(Hitmarker, {
		Speed = 100
	}, {ImageTransparency = 0}):AndThen(function()
AnimNation.target(Hitmarker, {
		Speed = 10
	}, {ImageTransparency = 1})
	end)

	
end


function CombatGui:FeedbackMessage(TargetPlayer, Message, PointsReward)


	local CombatFeedbackContainer = self.HUD.CombatFeedback
	local FeedbackFrame = CombatFeedbackContainer.FeedbackFrame:Clone()
	local FeedbackText = FeedbackFrame.FeedbackText
	local FeedbackPoints = FeedbackFrame.Reward

	FeedbackFrame.Parent = CombatFeedbackContainer
	local OriginalSizeY = FeedbackFrame.Size.Y.Scale

	FeedbackText.Text = Message
	FeedbackPoints.Text = "[+" .. tostring(PointsReward) .. "]"
	
	--thin out
	FeedbackFrame.Size = UDim2.fromScale(FeedbackFrame.Size.X.Scale, 0)
	FeedbackFrame.Visible = true

	--tween size
	AnimNation.target(
		FeedbackFrame,
		{Speed = 100},
		{Size = UDim2.fromScale(FeedbackFrame.Size.X.Scale, OriginalSizeY),
	
	}
	)

	task.delay(COMBAT_FEEDBACK_LIFETIME, function()
		AnimNation.target(
				FeedbackFrame,
				{Speed = 100},
				{Size = UDim2.fromScale(FeedbackFrame.Size.X.Scale, 0)}
			):AndThen(function()
				FeedbackFrame:Destroy()
			end)
	end)



	--note: since I'm lazy and don't wanna script custom list behavior I'm just gonna shrink the latest message asap
	
	--parent to elimination frame
	--play sound
	
	--set text to the target player's name and coin amount 
end

return CombatGui
