--manages physical items that can be picked up
--tzu made ts idk when he did

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Functions = require(ReplicatedStorage.Modules.Utils.Functions)

local PickupManager = {}

function PickupManager:Init(Core)
	self.StatusEffectManager = Core:Get("StatusEffectManager")

	self.Config = {
		MaxActive = 15,
		SpawnInterval = 3.0,
		PickupLifetime = 30,
		RaycastHeight = 80,
		RaycastDepth = 250,
		PickupGroundOffset = 1.25,
		DetectionRange = 6,
		DetectionFrequency = 0.1,
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
	rayParams.FilterDescendantsInstances = { self.PickupsFolder, spawnZone, workspace.SpatialQueryBlacklist }

	local activeCount = 0

	local function destroyPickup(pickup)
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

		if pickup:IsA("Model") then
			pickup:PivotTo(CFrame.new(groundPos))
		else
			pickup.CFrame = CFrame.new(groundPos)
		end

		self.ActivePickups[pickup] = {
			Pos = groundPos,
			Def = def,
			Instance = pickup,
			Collected = false,
		}
		activeCount += 1

		task.delay(self.Config.PickupLifetime, function()
			if self.ActivePickups[pickup] then
				destroyPickup(pickup)
			end
		end)
	end

	-- Detection loop
	task.spawn(function()
		while true do
			local startTime = os.clock()
			local players = Players:GetPlayers()
			local characterData = {}

			for _, plr in players do
				local char = plr.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then
					table.insert(characterData, { Plr = plr, Pos = root.Position })
				end
			end

			local detectionRangeSq = self.Config.DetectionRange ^ 2

			for pickup, data in self.ActivePickups do
				if data.Collected or not pickup.Parent then
					destroyPickup(pickup)
					continue
				end

				for _, char in characterData do
					local diff = char.Pos - data.Pos
					local distSq = diff.X * diff.X + diff.Y * diff.Y + diff.Z * diff.Z
					if distSq <= detectionRangeSq then
						-- Prevent stacking if plr alrd has this effect
						if data.Def.Id and self.StatusEffectManager:HasEffect(char.Plr, data.Def.Id) then
							continue
						end

						data.Collected = true
						local ok, err = pcall(data.Def.OnPickup, data.Def, char.Plr, self)
						destroyPickup(pickup)
						if not ok then warn(err) end
						break
					end
				end
			end
			task.wait(self.Config.DetectionFrequency)
		end
	end)

	-- Spawning loop
	task.spawn(function()
		while true do
			if activeCount < self.Config.MaxActive then
				spawnPickup()
			end
			task.wait(self.Config.SpawnInterval)
		end
	end)
end

return PickupManager
