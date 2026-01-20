local DonutClient = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local FoodModels = ReplicatedStorage.Assets.FoodModels

local HELD_C0 = CFrame.new(0.062, -0.834, -1.205) * CFrame.Angles(0, math.rad(90), 0)

function DonutClient:Init(Core)
	self.Core = Core
	self.ProjectileController = Core:Get("ProjectileController")
	self.CombatEvent = Core:Get("SharedRemotes"):GetEvent("CombatEvent")
	self.ClientDataController = Core:Get("ClientDataController")
	self.CharacterController = Core:Get("CharacterController")
	self.Config = require(ReplicatedStorage.Modules.Info.FoodCombatConfigs.DonutConfig)

	self.HeldModel = nil
	self.HeldMotor = nil
	self.HeldParts = nil
	self.HeldPartTransparency = nil

	self._throwConn = nil
	self._activeThrowId = nil
end

function DonutClient:_getRightArm(char: Model): BasePart?
	return (char:FindFirstChild("Right Arm") :: any)
		or (char:FindFirstChild("RightHand") :: any)
		or (char:FindFirstChild("RightLowerArm") :: any)
		or (char:FindFirstChild("RightUpperArm") :: any)
end

function DonutClient:_setHeldVisible(visible: boolean)
	local parts = self.HeldParts
	if not parts then
		return
	end

	if visible then
		local baseline = self.HeldPartTransparency
		for i = 1, #parts do
			local p = parts[i]
			p.Transparency = (baseline and baseline[p]) or 0
		end
	else
		for i = 1, #parts do
			parts[i].Transparency = 1
		end
	end
end

function DonutClient:_destroyHeld()
	if self.HeldMotor then
		self.HeldMotor:Destroy()
		self.HeldMotor = nil
	end
	if self.HeldModel then
		self.HeldModel:Destroy()
		self.HeldModel = nil
	end
	self.HeldParts = nil
	self.HeldPartTransparency = nil
end

function DonutClient:_ensureHeld()
	local char = LocalPlayer.Character
	if not char then
		return
	end
	if self.HeldModel and self.HeldModel.Parent == char then
		return
	end

	local donutTemplate = FoodModels:FindFirstChild("Donut")
	if not donutTemplate then
		return
	end

	local rightArm = self:_getRightArm(char)
	if not rightArm then
		return
	end

	local model = donutTemplate:Clone()
	model.Name = "HeldDonut"
	model.Parent = char

	local parts = table.create(8)
	local baseline = {}
	local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	model.PrimaryPart = primary

	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			baseline[d] = d.Transparency
			parts[#parts + 1] = d

			if d ~= primary then
				local w = d:FindFirstChildWhichIsA("WeldConstraint") or Instance.new("WeldConstraint")
				w.Part0 = d
				w.Part1 = primary
				w.Parent = d
			end
		end
	end

	local motor = Instance.new("Motor6D")
	motor.Name = "DonutMotor"
	motor.Part0 = rightArm
	motor.Part1 = primary
	motor.C0 = HELD_C0
	motor.Parent = rightArm

	self.HeldModel = model
	self.HeldMotor = motor
	self.HeldParts = parts
	self.HeldPartTransparency = baseline
end

function DonutClient:_syncHeld(inventory)
	local equipped = inventory and inventory.Equipped and inventory.Equipped.Food
	if equipped == "Donut" then
		self:_ensureHeld()
		return
	end

	if self._activeThrowId then
		self._activeThrowId = nil
		if self._throwConn then
			self._throwConn:Disconnect()
			self._throwConn = nil
		end
	end

	self:_destroyHeld()
end

function DonutClient:Start()
	self.CharacterController.CharacterLoaded:Connect(function()
		self:_syncHeld(self.ClientDataController.DataCache.Inventory)
	end)

	self.ClientDataController.InventoryChanged:Connect(function(inventory)
		self:_syncHeld(inventory)
	end)

	self:_syncHeld(self.ClientDataController.DataCache.Inventory)
end

function DonutClient:_animateBoomerang(
	owner: Player,
	projId: string,
	origin: Vector3,
	direction: Vector3,
	isLocalOwner: boolean,
	outDistance: number?
)
	local conf = self.Config.Projectile
	local range = conf.Range or 60
	local speed = conf.Speed or 120
	local returnSpeed = conf.ReturnSpeed or speed
	local arcHeight = conf.ArcHeight or 0
	local travelDist = math.clamp(outDistance or range, 5, range)

	local donutTemplate = FoodModels:FindFirstChild("Donut")
	if not donutTemplate then
		return
	end

	local model = donutTemplate:Clone()
	local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not primary then
		return
	end
	model.PrimaryPart = primary

	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Anchored = false
			if d ~= primary then
				local w = Instance.new("WeldConstraint")
				w.Part0 = d
				w.Part1 = primary
				w.Parent = d
			end
		end
	end
	primary.Anchored = true

	model.Parent = workspace.VisualEffectsCache or workspace
	primary.CFrame = CFrame.new(origin, origin + direction)

	local rayParams = self.ProjectileController and self.ProjectileController.RaycastParams
	local hitCharacters
	local hitCount = 0
	local maxHits = conf.MaxHits or 1

	if isLocalOwner then
		hitCharacters = {}
	end

	local outTime = travelDist / speed
	local t0 = tick()
	local phase = 0
	local lastPos = origin

	local function getReturnTarget(): Vector3
		local char = owner.Character
		if char then
			local arm = self:_getRightArm(char)
			if arm then
				return arm.Position
			end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				return hrp.Position
			end
		end
		return lastPos
	end

	local function cleanup()
		if self._throwConn and isLocalOwner then
			self._throwConn:Disconnect()
			self._throwConn = nil
			self._activeThrowId = nil
		end
		model:Destroy()
	end

	local function onHit(hitResult)
		if not isLocalOwner then
			return
		end
		if hitCount >= maxHits then
			return
		end

		local inst = hitResult.Instance
		local m = inst and inst:FindFirstAncestorWhichIsA("Model")
		local hum = m and m:FindFirstChildWhichIsA("Humanoid")
		if not hum then
			return
		end
		if hitCharacters[m] then
			return
		end
		hitCharacters[m] = true
		hitCount += 1

		self.CombatEvent:Fire(true, "Hit", {
			Sender = LocalPlayer,
			Combat = { FoodName = "Donut", Ultimate = false },
			Projectile = {
				Id = projId,
				HitResult = { Instance = inst, Position = hitResult.Position, Normal = hitResult.Normal },
			},
		})
	end

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if isLocalOwner and self._activeThrowId ~= projId then
			conn:Disconnect()
			cleanup()
			return
		end

		local now = tick()
		local pos
		local lookDir

		if phase == 0 then
			local alpha = (now - t0) / outTime
			if alpha >= 1 then
				alpha = 1
				phase = 1
			end
			pos = origin + direction * (travelDist * alpha) + Vector3.yAxis * (arcHeight * math.sin(alpha * math.pi))
			lookDir = direction
		else
			local target = getReturnTarget()
			local toTarget = target - lastPos
			local dist = toTarget.Magnitude
			if dist <= returnSpeed * dt then
				conn:Disconnect()
				if isLocalOwner then
					self:_setHeldVisible(true)
				end
				cleanup()
				return
			end
			lookDir = (dist > 0.001 and toTarget.Unit) or direction
			pos = lastPos + lookDir * (returnSpeed * dt)
		end

		local travel = pos - lastPos
		if rayParams and travel.Magnitude > 0.001 then
			local hit = workspace:Raycast(lastPos, travel, rayParams)
			if hit then
				onHit(hit)
			end
		end

		lastPos = pos
		local spin = now * 18
		primary.CFrame = CFrame.new(pos, pos + lookDir) * CFrame.Angles(0, 0, spin)
	end)

	if isLocalOwner then
		self._throwConn = conn
	end
end

function DonutClient:FireNormal()
	if self._activeThrowId then
		return
	end

	self:_ensureHeld()
	local held = self.HeldModel
	local char = LocalPlayer.Character
	if not char then
		return
	end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return
	end

	local origin = (held and held.PrimaryPart and held.PrimaryPart.Position) or (hrp.Position + hrp.CFrame.LookVector)
	local aimPos = Mouse.Hit.Position
	local aimVec = aimPos - origin
	if aimVec.Magnitude < 0.1 then
		aimVec = hrp.CFrame.LookVector
	end
	local dir = aimVec.Unit
	local maxRange = self.Config.Projectile.Range or 60
	local outDist = math.min(maxRange, aimVec.Magnitude)

	local projId = self.ProjectileController:GenerateProjectileId(LocalPlayer)
	self._activeThrowId = projId
	self:_setHeldVisible(false)

	local fireData = {
		Sender = LocalPlayer,
		Combat = { FoodName = "Donut", Ultimate = false },
		Projectile = {
			Id = projId,
			Owner = LocalPlayer,
			Origin = origin,
			Velocity = dir * (self.Config.Projectile.Speed or 120),
			Boomerang = {
				Range = self.Config.Projectile.Range,
				TargetDistance = outDist,
				Speed = self.Config.Projectile.Speed,
				ReturnSpeed = self.Config.Projectile.ReturnSpeed,
				ArcHeight = self.Config.Projectile.ArcHeight,
			},
		},
	}

	self.CombatEvent:Fire(true, "Fire", fireData)
	self:_animateBoomerang(LocalPlayer, projId, origin, dir, true, outDist)
end

function DonutClient:FireUltimate()
end

function DonutClient:FireReplicated(data)
	local owner = data.Sender
	local proj = data.Projectile
	if not owner or not proj then
		return
	end

	local velo = proj.Velocity
	if typeof(velo) ~= "Vector3" then
		return
	end
	local dir = velo.Magnitude > 0 and velo.Unit or Vector3.zAxis
	local boomerang = proj.Boomerang
	local outDist = boomerang and boomerang.TargetDistance
	self:_animateBoomerang(owner, proj.Id, proj.Origin, dir, false, outDist)
end

function DonutClient:OnUltimateActivated() end
function DonutClient:OnUltimateDeactivated() end

return DonutClient
