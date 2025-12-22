-- Purpose: Controls movement, parkour, character status effects, etc
--note: do not use for kill effects, i'll make a separate module for it
-- janin 12/12/25

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Camera = workspace.CurrentCamera

local Modules = ReplicatedStorage.Modules

--Imports--
local UtilFunctions = require(Modules.Utils.Functions)
local Janitor = require(Modules.Utils.Janitor)
local Signal = require(Modules.Utils.Signal)
local StateMachine = require(Modules.Utils.StateMachine)

local CharacterController = {}

function CharacterController:Init(Core)
	self.Core = Core
	--modules--
	self.SharedRemotes = Core:Get("SharedRemotes")
	self.CameraController = Core:Get("CameraController")
	self.InputController = Core:Get("InputController")
	--remotes--
	self.CharacterEvent = self.SharedRemotes:GetEvent("CharacterEvent")

	-- Current local character & components
	self.Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	self.Humanoid = self.Character.Humanoid
	self.HRP = self.Humanoid.RootPart
	self.CharacterLoaded = false

	--Janitors--
	self._janitor = Janitor.new()

	self:SetupCharacter(self.Character) --initial load if characteradded event doesn't work--

	LocalPlayer.CharacterAdded:Connect(function(char: Model)
		if not self.Character then --makes sure you don't double load
			self:SetupCharacter(char)
		end
	end)

	--Cleanup on character death/removal
	LocalPlayer.CharacterRemoving:Connect(function(character)
		self:Cleanup()
	end)

	--setup input management--
	self.InputController:
end

-- Called from StarterCharacterScripts
function CharacterController:SetupCharacter(char: Model)
	--setup character components and refresh module variables
	self.Character = self._janitor:Add(char) --humanoid and HRP should automatically be deleted(obviously) with character
	self.Humanoid = char:WaitForChild("Humanoid")
	self.HRP = char:WaitForChild("HumanoidRootPart")
	self.CharacterLoaded = true

	self.ParkourConfig = {
		--Movement--
		walkAlpha = 8, --smooth walking
		baseSpeed = 20,
		maxSpeed = 30,
		runAccel = 2,
		moveVelocity = Vector3.zero,

		--tilting/rotating
		characterRotSpeed = 5,
		tiltSpeed = 10,
		maxTiltAngle = 10,
		rotateHRPWithCamera = false,
		defaultC0 = self.HRP.RootJoint.C0,
	}

	self.ParkourStates = self._janitor:AddObject(StateMachine.new())
	--state machine for parkour actions like wallrunning, sliding, vaulting, etc
	--state machine has a Destroy method so this should work

	--shortened variables
	local hum = self.Humanoid
	local char = self.Character
	local hrp = self.HRP

	--parkour vars
	local ParkourStates = self.ParkourStates
	local ParkourConfig = self.ParkourConfig
	--set up binds--

	--setup initial movement--
	hum.WalkSpeed = ParkourConfig.baseSpeed
	hum.UseJumpPower = true
	hum.AutoRotate = false

	hum.Died:Connect(function()
		self:_humanoidDied()
	end)

	self._janitor:Add(RunService.PreRender:Connect(function(dt)
		--if ragdolled then return  end

		self:_updateHRPOrientation(dt)
		self:_updateMovement(dt)
		self:_vaultUpdate(dt)
	end))

	-- Optionally clear old state
	self.StatusEffects = {}
end

-- Example stub for status effects
function CharacterController:ApplyStatusEffect(name: string, data: table)
	-- Example:
	-- data = { Duration = 3, SpeedMultiplier = 0.5 }
	self.StatusEffects[name] = {
		Data = data,
		ExpiresAt = tick() + (data.Duration or 0),
	}

	-- You’d then have an update loop someplace (e.g. RunService.Heartbeat in another method)
	-- that checks StatusEffects and applies/removes effects as needed.
end

function CharacterController:UpdateStatusEffects() end

function CharacterController:ClearStatusEffect(name: string)
	self.StatusEffects[name] = nil
end

function CharacterController:GetCharacter()
	return self.Character, self.Humanoid, self.HRP
end

function CharacterController:Cleanup() --refreshes everything to be reusable
	self._janitor:Cleanup()
	warn("janitor now cleaning up")
end

--private--

--handles walking movement stuff
function CharacterController:_updateMovement(dt)
	--shortened variables
	local hum = self.Humanoid
	local char = self.Character
	local hrp = self.HRP

	--parkour vars
	local ParkourStates = self.ParkourStates
	local ParkourConfig = self.ParkourConfig

	if not (ParkourStates:IsState("ZipLining") or hum:GetState() == Enum.HumanoidStateType.Physics) then
		--movement "slip" effect--
		ParkourConfig.moveVelocity = UtilFunctions.Lerp(
			ParkourConfig.moveVelocity,
			hum.MoveDirection,
			math.clamp(dt * ParkourConfig.walkAlpha, 0, 1)
		)

		--hum:Move(ParkourConfig.moveVelocity)

		--walkspeed acceleration--
		if hum.MoveDirection.Magnitude > 0 then
			hum.WalkSpeed =
				math.clamp(hum.WalkSpeed + ParkourConfig.runAccel * dt, ParkourConfig.baseSpeed, ParkourConfig.maxSpeed)
		else
			hum.WalkSpeed = ParkourConfig.baseSpeed
		end
	end
end

--controls leaning and root part orientation
function CharacterController:_updateHRPOrientation(dt)
	--shortened variables
	local hum = self.Humanoid
	local char = self.Character
	local hrp = self.HRP
	local RootJoint = hrp.RootJoint

	--parkour vars
	local ParkourStates = self.ParkourStates
	local ParkourConfig = self.ParkourConfig

	local LeanMoveDirection = hrp.CFrame:VectorToObjectSpace(hum.MoveDirection)
	--print(LeanMoveDirection)

	RootJoint.C0 = RootJoint.C0:Lerp(
		ParkourConfig.defaultC0
			* CFrame.Angles(
				math.rad(-LeanMoveDirection.Z) * ParkourConfig.maxTiltAngle,
				math.rad(-LeanMoveDirection.X) * ParkourConfig.maxTiltAngle,
				0
			),
		dt * ParkourConfig.tiltSpeed
	)

	--guard clause--
	if not self.ParkourConfig.rotateHRPWithCamera then
		hum.AutoRotate = true
		return
	end

	hum.AutoRotate = false

	local _, y, _ = Camera.CFrame:ToOrientation()

	hrp.CFrame =
		hrp.CFrame:Lerp(CFrame.new(hrp.Position) * CFrame.Angles(0, y, 0), dt * 5 * ParkourConfig.characterRotSpeed)
end

function CharacterController:_humanoidDied()

	--self.HRP:ApplyImpulse(self.HRP:GetMass() * Vector3.yAxis * 500)
	--self.HRP:ApplyAngularImpulse(self.HRP:GetMass() * Vector3.one * math.random(100, 500))
end

--simple increase of hrp assembly linear velocity
function CharacterController:_vaultUpdate()
	local hum = self.Humanoid
	local hrp = hum.RootPart

	if StateMachine:IsState("Vaulting") then
		hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 25, hrp.AssemblyLinearVelocity.Z)
	end
end

return CharacterController
