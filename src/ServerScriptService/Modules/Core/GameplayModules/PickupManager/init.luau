local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Functions = require(ReplicatedStorage.Modules.Utils.Functions)

local PickupManager = {}

function PickupManager:Init(Core)
	self.StatusEffectManager = Core:Get("StatusEffectManager")

	self.Config = {
		MaxActive = 10,
		SpawnInterval = 3.5,
		PickupLifetime = 25,
		RaycastHeight = 80,
		RaycastDepth = 250,
		PickupGroundOffset = 1.25,
	}

	self.ActivePickups = {}

	self.PickupsFolder = workspace:FindFirstChild("Pickups") or Instance.new("Folder")
	self.PickupsFolder.Name = "Pickups"
	self.PickupsFolder.Parent = workspace

	self.PickupDefs = {}
	for _, moduleScript in script.Pickups:GetChildren() do
		local def = require(moduleScript)
		def.Id = def.Id or moduleScript.Name
		table.insert(self.PickupDefs, def)
	end
end

function PickupManager:Start()
	local spawnZone = workspace.Zones.SpawnZone
	local parts = spawnZone:IsA("BasePart") and {spawnZone, unpack(spawnZone:QueryDescendants("BasePart"))} 
		or spawnZone:QueryDescendants("BasePart")

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { self.PickupsFolder, spawnZone, workspace.VisualEffectsCache }

	local activeCount = 0

	local function destroyPickup(pickup, touchConn)
		if touchConn then
			touchConn:Disconnect()
		end
		if self.ActivePickups[pickup] then
			self.ActivePickups[pickup] = nil
			activeCount -= 1
		end
		if pickup and pickup.Parent then
			pickup:Destroy()
		end
	end

	local function spawnPickup()
		local def = self.PickupDefs[math.random(1, #self.PickupDefs)]
		local zonePart = parts[math.random(1, #parts)]

		local rx = (math.random() - 0.5) * zonePart.Size.X
		local rz = (math.random() - 0.5) * zonePart.Size.Z
		local xzPoint = zonePart.CFrame:PointToWorldSpace(Vector3.new(rx, 0, rz))

		local origin = Vector3.new(xzPoint.X, zonePart.Position.Y + self.Config.RaycastHeight, xzPoint.Z)
		local hit = workspace:Raycast(origin, Vector3.new(0, -self.Config.RaycastDepth, 0), rayParams)
		local groundPos = (hit and hit.Position or xzPoint) + Vector3.new(0, self.Config.PickupGroundOffset, 0)

		local pickup = def:Create()
		pickup:SetAttribute("PickupId", def.Id)
		pickup.Parent = self.PickupsFolder

		local collider
		if pickup:IsA("Model") then
			collider = pickup.PrimaryPart or pickup:FindFirstChildWhichIsA("BasePart")
			pickup.PrimaryPart = collider
			pickup:PivotTo(CFrame.new(groundPos))
		else
			collider = pickup
			pickup.CFrame = CFrame.new(groundPos)
		end

		self.ActivePickups[pickup] = true
		activeCount += 1

		local collected = false
		local touchConn
		touchConn = collider.Touched:Connect(function(hitPart)
			if collected then
				return
			end

			local _, plr = Functions.FindCharacter(hitPart)
			if not plr then
				return
			end

			collected = true
			local ok, err = pcall(def.OnPickup, def, plr, self)
			destroyPickup(pickup, touchConn)
			if not ok then
				warn(err)
			end
		end)

		task.delay(self.Config.PickupLifetime, function()
			destroyPickup(pickup, touchConn)
		end)
	end

	task.spawn(function()
		while true do
			for pickup in pairs(self.ActivePickups) do
				if not pickup.Parent then
					self.ActivePickups[pickup] = nil
					activeCount -= 1
				end
			end

			if activeCount < self.Config.MaxActive then
				spawnPickup()
			end

			task.wait(self.Config.SpawnInterval)
		end
	end)
end

return PickupManager
