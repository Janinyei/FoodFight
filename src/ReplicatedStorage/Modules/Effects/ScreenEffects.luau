local ScreenEffects = {}

local player = game.Players.LocalPlayer

local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")

local vignetteTemplate = replicatedStorage.Assets.UI.Vignette
local defaultColor = Color3.fromRGB(255, 85, 0)

function ScreenEffects.Vignette(color, targetTransparency, initialTransparency, duration)
	local vignette = vignetteTemplate:Clone()
	local image = vignette:WaitForChild("Image")
	image.ImageColor3 = color or defaultColor
	image.ImageTransparency = initialTransparency or 0.8
	vignette.Parent = player.PlayerGui
	local tween = tweenService:Create(image, TweenInfo.new(duration or 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0), {
		ImageTransparency = targetTransparency or 0.4
	})
	tween:Play()
	return function()
		tween:Cancel()
		local fadeOutTween = tweenService:Create(image, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {ImageTransparency = 1})
		fadeOutTween:Play()
		fadeOutTween.Completed:Wait()
		vignette:Destroy()
	end
end

local comboStopVignette = nil
local comboTier = 0

local function getTier(count: number): number
	if count >= 10 then
		return 4
	end
	if count >= 5 then
		return 3
	end
	if count >= 3 then
		return 2
	end
	if count >= 1 then
		return 1
	end
	return 0
end

function ScreenEffects.ResetCombo()
	if comboStopVignette then
		task.spawn(comboStopVignette)
	end
	comboStopVignette = nil
	comboTier = 0
end

function ScreenEffects.SetCombo(comboCount: number)
	comboCount = tonumber(comboCount) or 0
	if comboCount <= 0 then
		ScreenEffects.ResetCombo()
		return
	end

	local intensity = math.clamp(comboCount / 10, 0, 1)
	local tier = getTier(comboCount)

	local targetTint = defaultColor:Lerp(Color3.fromRGB(170, 0, 255), intensity)
	local initialTransparency = 0.92 - (0.35 * intensity)
	local targetTransparency = 0.82 - (0.55 * intensity)
	local duration = 0.4 - (0.2 * intensity)

	if tier ~= comboTier or not comboStopVignette then
		if comboStopVignette then
			task.spawn(comboStopVignette)
			comboStopVignette = nil
		end
		comboTier = tier
		comboStopVignette = ScreenEffects.Vignette(targetTint, targetTransparency, initialTransparency, duration)
	end
end

return ScreenEffects
