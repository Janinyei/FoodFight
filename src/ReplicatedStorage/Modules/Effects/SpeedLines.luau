local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Modules
local Janitor = require(Modules.Utils.Janitor)

local Camera = workspace.CurrentCamera
local Assets = ReplicatedStorage.Assets
local Effects = Assets:WaitForChild("Effects")

local SpeedLines = {}

function SpeedLines:Play(rate: number?)
	if not Camera then
		return nil
	end

	local template = Effects:FindFirstChild("CameraSpeedLines")
	if not template then
		return nil
	end

	local janitor = Janitor.new()
	local lines = template:Clone()
	local emitter = lines:FindFirstChild("Emitter", true)

	if emitter and emitter:IsA("ParticleEmitter") and rate then
		emitter.Rate = rate
	end

	lines.Parent = Camera

	janitor:Add(RunService.RenderStepped:Connect(function()
		if not lines.Parent then
			return
		end

		local ok = pcall(function()
			lines.CFrame = Camera.CFrame * CFrame.Angles(-math.pi / 2, 0, 0)
		end)
		if not ok and lines:IsA("Model") then
			local primary = lines.PrimaryPart or lines:FindFirstChildWhichIsA("BasePart")
			if primary then
				lines:PivotTo(Camera.CFrame * CFrame.Angles(-math.pi / 2, 0, 0))
			end
		end
	end))

	janitor:Add(function()
		local emitterToDisable = emitter
		local linesToDestroy = lines

		task.spawn(function()
			if emitterToDisable and emitterToDisable:IsA("ParticleEmitter") then
				emitterToDisable.Enabled = false
				task.wait(emitterToDisable.Lifetime.Max)
			end
			if linesToDestroy and linesToDestroy.Parent then
				linesToDestroy:Destroy()
			end
		end)
	end, true)

	return janitor
end

return SpeedLines
