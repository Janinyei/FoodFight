local LaserEyes = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UtilFunctions = require(ReplicatedStorage.Modules.Utils.Functions)

local function setAttachmentWorldPosition(att: Attachment, worldPos: Vector3)
	local parentPart = att.Parent
	if parentPart and parentPart:IsA("BasePart") then
		att.CFrame = parentPart.CFrame:ToObjectSpace(CFrame.new(worldPos))
	end
end

local function applyBurn(targetCharacter: Model, targetPart: BasePart?)
	local torso = targetCharacter:FindFirstChild("Torso") or targetCharacter:FindFirstChild("UpperTorso") or targetPart
	local burnTemplate = ReplicatedStorage.Assets.KillEffects:FindFirstChild("Burnt")
	if torso and burnTemplate then
		burnTemplate:Clone().Parent = torso
	end

	local shirt = targetCharacter:FindFirstChildOfClass("Shirt")
	if shirt then
		shirt:Destroy()
	end
	local pants = targetCharacter:FindFirstChildOfClass("Pants")
	if pants then
		pants:Destroy()
	end
	local shirtGraphic = targetCharacter:FindFirstChildOfClass("ShirtGraphic")
	if shirtGraphic then
		shirtGraphic:Destroy()
	end

	for _, part in targetCharacter:QueryDescendants("BasePart") do
		local surfaceAppearance = part:FindFirstChildOfClass("SurfaceAppearance")
		if surfaceAppearance then
			surfaceAppearance:Destroy()
		end
		part.Material = Enum.Material.Plastic
		part.Color = Color3.fromRGB(0, 0, 0)
	end
end

function LaserEyes:PlayKillEffect(data, Core)
	local targetCharacter = data.TargetCharacter
	local killer = data.Killer
	local victim = data.Victim

	UtilFunctions.ToggleRagdoll(targetCharacter, true)

	if killer and victim and killer == victim then
		if targetCharacter then
			local targetPart = targetCharacter:FindFirstChild("HumanoidRootPart") or targetCharacter:FindFirstChild("Head")
			if targetPart and targetPart:IsA("BasePart") then
				applyBurn(targetCharacter, targetPart)
			else
				applyBurn(targetCharacter, nil)
			end
		end
		return
	end

	if not (targetCharacter and killer and killer.Character) then
		return
	end

	local killerCharacter = killer.Character
	local head = killerCharacter:FindFirstChild("Head")
	local targetPart = targetCharacter:FindFirstChild("HumanoidRootPart") or targetCharacter:FindFirstChild("Head")
	if not (head and targetPart) then
		return
	end

	applyBurn(targetCharacter, targetPart)

	local template = ReplicatedStorage.Assets.KillEffects:FindFirstChild("LaserEyes")
	if not template then
		return
	end

	local fx = template:Clone()
	fx.Parent = workspace:FindFirstChild("SpatialQueryBlacklist") or workspace

	local charge = fx:FindFirstChild("Charge", true)
	local burst = fx:FindFirstChild("Burst", true)
	local beam1 = fx:FindFirstChild("Beam1", true)
	local beam2 = fx:FindFirstChild("Beam2", true)
	local collision1 = fx:FindFirstChild("Collision1", true)
	local collision2 = fx:FindFirstChild("Collision2", true)

	local duration = 0.35
	local maxDistance = 45
	local beamThickness = 0.35
	
	if killer == Players.LocalPlayer then
		local cameraController = Core and Core:Get("CameraController")
		if cameraController and cameraController.Shake then
			cameraController:Shake(0.35, 20, 0.05, duration)
		end
	end

	local function prepPart(part: BasePart, anchored: boolean)
		part.Anchored = anchored
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
	end

	if charge and charge:IsA("BasePart") then
		prepPart(charge, false)
		charge.CFrame = head.CFrame * CFrame.new(0, -0.2, 0.5)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = charge
		weld.Parent = charge
	end

	if burst and burst:IsA("BasePart") then
		prepPart(burst, false)
		burst.CFrame = head.CFrame * CFrame.new(0, -0.2, 0.5)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = burst
		weld.Parent = burst
		--[[local sound = burst:FindFirstChildWhichIsA("Sound", true)
		if sound then
			sound:Play()
		end]]
	end

	if beam1 and beam1:IsA("BasePart") then
		prepPart(beam1, true)
	end

	if beam2 and beam2:IsA("BasePart") then
		prepPart(beam2, true)
	end

	if collision1 and collision1:IsA("BasePart") then
		prepPart(collision1, true)
		local trail = collision1:FindFirstChildWhichIsA("Trail", true)
		if trail then
			trail.Enabled = true
		end
	end

	if collision2 and collision2:IsA("BasePart") then
		prepPart(collision2, true)
		local trail = collision2:FindFirstChildWhichIsA("Trail", true)
		if trail then
			trail.Enabled = true
		end
	end

	local function setBeamPart(part: BasePart, fromPos: Vector3, toPos: Vector3)
		local delta = toPos - fromPos
		local len = delta.Magnitude
		if len < 0.01 then
			len = 0.01
			toPos = fromPos + Vector3.zAxis
		end

		part.Size = Vector3.new(beamThickness, beamThickness, len)
		part.CFrame = CFrame.new(fromPos, toPos) * CFrame.new(0, 0, -len * 0.5) * CFrame.Angles(0, 0, math.pi * 0.5)

		local startObj = part:FindFirstChild("Start")
		if startObj and (startObj:IsA("Attachment") or startObj:IsA("BasePart")) then
			startObj.Position = Vector3.new(0, 0, len * 0.5)
		end

		local endObj = part:FindFirstChild("End")
		if endObj and (endObj:IsA("Attachment") or endObj:IsA("BasePart")) then
			endObj.Position = Vector3.new(0, 0, -len * 0.5)
		end
	end

	local function setBeam(beamObj: Instance?, originAtt: Attachment, endAtt: Attachment, fromPos: Vector3, toPos: Vector3)
		if not beamObj then
			return
		end

		if beamObj:IsA("Beam") then
			beamObj.Attachment0 = originAtt
			beamObj.Attachment1 = endAtt
			setAttachmentWorldPosition(endAtt, toPos)
			return
		end

		if beamObj:IsA("BasePart") then
			setBeamPart(beamObj, fromPos, toPos)
		end
	end

	local originL = Instance.new("Attachment")
	originL.Name = "LaserOriginL"
	originL.Position = Vector3.new(0.2, 0.2, 0)
	originL.Parent = head

	local originR = Instance.new("Attachment")
	originR.Name = "LaserOriginR"
	originR.Position = Vector3.new(-0.2, 0.2, 0)
	originR.Parent = head

	local endLAtt = Instance.new("Attachment")
	endLAtt.Name = "LaserEndL"
	endLAtt.Parent = targetPart

	local endRAtt = Instance.new("Attachment")
	endRAtt.Name = "LaserEndR"
	endRAtt.Parent = targetPart

	local conn
	local function cleanup()
		if conn then
			conn:Disconnect()
			conn = nil
		end
		originL:Destroy()
		originR:Destroy()
		endLAtt:Destroy()
		endRAtt:Destroy()
		fx:Destroy()
	end

	conn = RunService.RenderStepped:Connect(function()
		if not (fx.Parent and killerCharacter.Parent and targetCharacter.Parent and head.Parent) then
			cleanup()
			return
		end

		local targetPos = targetPart.Position + Vector3.yAxis * 0.15
		local originLPos = originL.WorldPosition
		local originRPos = originR.WorldPosition

		local endL = targetPos
		local deltaL = endL - originLPos
		local distL = deltaL.Magnitude
		if distL > maxDistance then
			endL = originLPos + deltaL * (maxDistance / distL)
		end

		local endR = targetPos
		local deltaR = endR - originRPos
		local distR = deltaR.Magnitude
		if distR > maxDistance then
			endR = originRPos + deltaR * (maxDistance / distR)
		end

		setBeam(beam1, originL, endLAtt, originLPos, endL)
		setBeam(beam2, originR, endRAtt, originRPos, endR)

		if collision1 and collision1:IsA("BasePart") then
			collision1.Position = endL
		elseif collision1 and collision1:IsA("Attachment") then
			setAttachmentWorldPosition(collision1, endL)
		end
		if collision2 and collision2:IsA("BasePart") then
			collision2.Position = endR
		elseif collision2 and collision2:IsA("Attachment") then
			setAttachmentWorldPosition(collision2, endR)
		end
	end)

	task.delay(duration, cleanup)
end

return LaserEyes

