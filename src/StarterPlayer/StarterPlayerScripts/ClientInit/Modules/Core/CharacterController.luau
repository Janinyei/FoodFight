-- Purpose: Controls movement, parkour, character status effects, etc
--note: do not use for kill effects, i'll make a separate module for it
-- janin 12/12/25

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Debris = game:GetService("Debris")

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

	LocalPlayer.CharacterAdded:Connect(function(char: Model)
		print(self.Character)
		--	if not self.Character then --makes sure you don't double load. --note: this conditional actually prevented people from reloading their charactercontroller after respawning

		self:SetupCharacter(char)
		--	end
	end)

	--Cleanup on character death/removal
	LocalPlayer.CharacterRemoving:Connect(function(character)
		self:Cleanup()
	end)
end

function CharacterController:Start()
	self:SetupCharacter(self.Character) --initial load if characteradded event doesn't work--
end

-- Called from StarterCharacterScripts
function CharacterController:SetupCharacter(char: Model)
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

		--crouching--
		isCrouching = false,
		crouchHeight = -2,
		crouchSpeed = 16, --crouch walkspeed
		crouchTransitionSpeed = 5,

		--tilting/rotating
		characterRotSpeed = 5,
		tiltSpeed = 10,
		maxTiltAngle = 10,
		rotateHRPWithCamera = true,
		defaultC0 = self.HRP.RootJoint.C0,

		--vaulting--
		maxWallVaultDistance = 10,
		maxLedgeHeight = 10,
		vaultDuration = 0.25,

		--sliding--
		defaultSlideDuration = 4,
		slideMaxCeilingHeight = 3, --ceiling height for someone sliding underneath a surface
		slideSpeed = 50,
		slideTiltMax = 45,

		--multi/double jumping
		baseJumpPower = 30,
		currentJumps = 0,
		maxJumps = 2,

		--sliding--
		slideHopSpeedIncrement = 15,

		--dashing--
		dashVelocity = 25,
		dashCooldown = 1,
		dashTick = tick(),
		dashDuration = 0.15,

		--gravity--
		baseGravity = 90,
	}

	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude
	RayParams.FilterDescendantsInstances = { workspace.VisualEffectsCache, self.Character }

	self.ParkourRayParams = RayParams
	self.ParkourStates = self._janitor:AddObject(StateMachine.new())

	--state machine for parkour actions like wallrunning, sliding, vaulting, etc
	--state machine has a Destroy method so this should work

	--shortened variables
	local hum = self.Humanoid
	local char = self.Character
	local hrp = self.HRP

	hrp.Transparency = 0

	--parkour vars
	local ParkourStates = self.ParkourStates
	local ParkourConfig = self.ParkourConfig
	--set up bind actions--
	--setup input management--
	self.InputController:SetActionCallback("UpAction", function(state, inputObj)
		if state == Enum.UserInputState.Begin then
			--slide canceling for bhopping
			if ParkourStates:IsState("Sliding") then
				self:_deactivateSlide()
			end

			--forward ray for vaulting
			local FrontRay = workspace:Raycast(
				hrp.CFrame.Position,
				hrp.CFrame.LookVector * ParkourConfig.maxWallVaultDistance,
				RayParams
			)

			--vaulting activation--
			if FrontRay then
				local Angle = math.deg(FrontRay.Normal:Angle((hrp.Position - FrontRay.Position).Unit))
				print(Angle)
				if Angle <= 40 then
					local LedgeRay = workspace:Raycast(
						FrontRay.Position + hrp.CFrame.LookVector * 0.1 + Vector3.yAxis * ParkourConfig.maxLedgeHeight,
						Vector3.yAxis * -ParkourConfig.maxLedgeHeight,
						RayParams
					)

					if LedgeRay then
						ParkourStates:SetState("Vaulting")
						--	hrp:ApplyImpulse(Vector3.yAxis * 100 * hrp:GetMass())
					end

					task.delay(ParkourConfig.vaultDuration, function() --idk if this would cause problems but we'll see
						if ParkourStates:IsState("Vaulting") then ---put in place to prevent annoying interruptions from task.delay
							ParkourStates:ClearState()
						end
					end)
				end
			end

			--multi jump(make sure this after the front ray logic)--
			if not ParkourStates:IsState("Vaulting") then
				self:_multiJump()
			end
		end
	end)

	self.InputController:SetActionCallback("Dash", function(state, inputObj)
		--set up guard clause--
		if state == Enum.UserInputState.Begin then
			self:_dash()
		end
	end)

	self.InputController:SetActionCallback("DownAction", function(state, inputObj)
		local moveDir = self.Humanoid.MoveDirection

		if state == Enum.UserInputState.Begin then
			-- If player is pushing WASD/Joystick, Slide. Otherwise, Crouch.
			if moveDir.Magnitude > 0 then
				self:_activateSlide()
			else
				self:_startCrouch()
			end
		elseif state == Enum.UserInputState.End then
			-- Stop both regardless of which one was active
			if self.ParkourStates:IsState("Sliding") then
				self:_deactivateSlide()
			end
			self:_stopCrouch()
		end
	end)
	--setup initial movement--
	hum.WalkSpeed = ParkourConfig.baseSpeed
	hum.UseJumpPower = true
	hum.AutoRotate = false --very necessary
	hum.JumpPower = ParkourConfig.baseJumpPower

	--workspace.Gravity = ParkourConfig.baseGravity

	hum.Died:Connect(function()
		self:_humanoidDied()
	end)

	--humanoid state change actions--

	hum.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Running then
			--reset current jumps--

			self.ParkourConfig.currentJumps = 0
		elseif new == Enum.HumanoidStateType.Jumping then
			--add single jump--
			self.ParkourConfig.currentJumps += 1
			print("regular jump")
		end
	end)

	self._janitor:Add(RunService.PreRender:Connect(function(dt)
		self:_updateHRPOrientation(dt)
		self:_updateMovement(dt)
		self:_vaultUpdate(dt)
		self:_slideUpdate(dt)
	end))

	print("character loaded")
end

function CharacterController:GetCharacter()
	return self.Character, self.Humanoid, self.HRP
end

function CharacterController:Cleanup() --refreshes everything to be reusable
	self._janitor:Cleanup()
	warn("janitor now cleaning up")
end

--private--

--crouching
function CharacterController:_startCrouch()
	self.ParkourConfig.isCrouching = true
end

function CharacterController:_stopCrouch()
	-- Only stop if there's no ceiling above
	local rayOrigin = self.HRP.Position
	local rayDirection = Vector3.yAxis * 3 -- Check 3 studs up
	local ceilingRay = workspace:Raycast(rayOrigin, rayDirection, self.ParkourRayParams)

	if not ceilingRay then
		self.ParkourConfig.isCrouching = false
	else
		-- If blocked, stay crouching (you could add an "Auto-Stand" flag here later)
		self.ParkourConfig.isCrouching = true
	end
end

--handles walking movement stuff
function CharacterController:_updateMovement(dt)
	--shortened variables
	local hum = self.Humanoid
	local char = self.Character
	local hrp = self.HRP

	--parkour vars
	local ParkourStates = self.ParkourStates
	local ParkourConfig = self.ParkourConfig

	if not (ParkourStates:IsState("Sliding") or hum:GetState() == Enum.HumanoidStateType.Physics) then
		--movement "slip" effect--
		ParkourConfig.moveVelocity = UtilFunctions.Lerp(
			ParkourConfig.moveVelocity,
			hum.MoveDirection,
			math.clamp(dt * ParkourConfig.walkAlpha, 0, 1)
		)
		--hum:Move(ParkourConfig.moveVelocity)
		local targetHeight = self.ParkourConfig.isCrouching and self.ParkourConfig.crouchHeight or 0
		--hip height adjustment
		self.Humanoid.HipHeight = UtilFunctions.Lerp(self.Humanoid.HipHeight, targetHeight, dt * self.crouchTransitionSpeed)

		local targetWalkspeed = ParkourConfig.isCrouching and ParkourConfig.crouchSpeed or ParkourConfig.baseSpeed
		--walkspeed acceleration--
		if hum.MoveDirection.Magnitude > 0 then
			hum.WalkSpeed = math.clamp(hum.WalkSpeed + ParkourConfig.runAccel * dt, 0, targetWalkspeed)
		else
			hum.WalkSpeed = targetWalkspeed
		end
	end
end

--controls leaning and root part orientation
function CharacterController:_updateHRPOrientation(dt)
	if self.ParkourStates:IsState("Sliding") then
		return
	end
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

--simple adjustment of hrp assembly linear velocity
function CharacterController:_vaultUpdate(dt)
	local hum = self.Humanoid
	local hrp = hum.RootPart

	if self.ParkourStates:IsState("Vaulting") then
		hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 25, hrp.AssemblyLinearVelocity.Z)
	end
end

--sliding

function CharacterController:_activateSlide()
	if self.Humanoid:GetState() == Enum.HumanoidStateType.Running and self.Humanoid.MoveDirection.Magnitude ~= 0 then
		print("slide trigger")

		local hum = self.Humanoid
		local hrp = hum.RootPart

		local DownRay = workspace:Raycast(self.HRP.Position, Vector3.yAxis * -5, self.ParkourRayParams)

		if DownRay and self.Humanoid.WalkSpeed > 0 then
			self.ParkourStates:SetState("Sliding")
			self.ParkourConfig.rotateHRPWithCamera = false
			hum.AutoRotate = false
			hum:ChangeState(Enum.HumanoidStateType.Physics)

			-- 1. Setup LinearVelocity for movement
			local lv = hrp:FindFirstChild("SlideVelocity") or Instance.new("LinearVelocity")
			lv.Name = "SlideVelocity"
			lv.Attachment0 = hrp:WaitForChild("RootAttachment")
			lv.MaxForce = 100000 -- High force for responsiveness
			lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
			lv.VectorVelocity = hrp.AssemblyLinearVelocity
			lv.Parent = hrp
			lv.Enabled = true

			-- 2. Setup AlignOrientation to keep HRP upright (Yaw only)
			local ao = hrp:FindFirstChild("SlideOrientation") or Instance.new("AlignOrientation")
			ao.Name = "SlideOrientation"
			ao.Attachment0 = hrp.RootAttachment
			ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
			ao.RigidityEnabled = false
			ao.MaxTorque = 1000000
			ao.Responsiveness = 25
			ao.CFrame = CFrame.new(hrp.Position) * hrp.CFrame.Rotation
			ao.Parent = hrp
			ao.Enabled = true
			--use initial veloci
		end
	end
end

function CharacterController:_slideUpdate(dt)
	if not self.ParkourStates:IsState("Sliding") then
		return
	end

	local hrp = self.HRP
	local RootJoint = hrp.RootJoint
	local lv = hrp:FindFirstChild("SlideVelocity")
	local ao = hrp:FindFirstChild("SlideOrientation")

	self.Humanoid.AutoRotate = false

	local DownRay = workspace:Raycast(self.HRP.Position, Vector3.yAxis * -5, self.ParkourRayParams)

	if DownRay then
		-- 1. CALCULATE MOVEMENT (LinearVelocity)
		local currentVel = hrp.AssemblyLinearVelocity
		-- Project current movement onto the slope plane
		local planeVel = currentVel - DownRay.Normal * currentVel:Dot(DownRay.Normal)

		-- Add downhill pull based on slope steepness
		local downhill = -Vector3.yAxis - (-Vector3.yAxis:Dot(DownRay.Normal) * DownRay.Normal)
		local targetVel = planeVel + downhill -- Adjust 15 for slope speed boost

		-- Apply slight friction so they eventually stop on flat ground
		if downhill.Magnitude < 0.1 then
			targetVel *= 0.98
		end

		lv.VectorVelocity = targetVel

		-- 2. CALCULATE HRP ROTATION (AlignOrientation - Yaw Only)
		local moveDir = UtilFunctions.V3Flat(targetVel)
		if moveDir.Magnitude > 0.5 then
			-- We keep Pitch and Roll at 0 to stay upright
			ao.CFrame = CFrame.lookAt(Vector3.zero, targetVel.Unit)
		end

		-- Auto-cancel slide if too slow
		if targetVel.Magnitude < 5 then
			self:_deactivateSlide()
		end
	else
		self:_deactivateSlide()
	end
end

function CharacterController:_deactivateSlide()
	if not self.ParkourStates:IsState("Sliding") then
		return
	end

	self.ParkourStates:ClearState()
	self.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
	self.ParkourConfig.rotateHRPWithCamera = true

	-- Disable constraints
	local lv = self.HRP:FindFirstChild("SlideVelocity")
	local ao = self.HRP:FindFirstChild("SlideOrientation")
	if lv then
		lv.Enabled = false
	end
	if ao then
		ao.Enabled = false
	end

	--check ceiling

	local ceilingRay = workspace:Raycast(self.HRP.Position, Vector3.yAxis * 5, self.ParkourRayParams)

	if ceilingRay then
		self:_startCrouch()
	end

	self:_slideHop()
end

function CharacterController:_slideHop()
	self.HRP.AssemblyLinearVelocity += UtilFunctions.V3Flat(self.HRP.AssemblyLinearVelocity.Unit * 25)
end
--multi jump--

function CharacterController:_multiJump()
	if self.ParkourConfig.currentJumps < self.ParkourConfig.maxJumps and self.ParkourConfig.currentJumps >= 1 then
		self.ParkourConfig.currentJumps += 1
		local currentVelo = self.HRP.AssemblyLinearVelocity
		self.HRP.AssemblyLinearVelocity =
			Vector3.new(currentVelo.X, self.ParkourConfig.baseJumpPower * 1.5, currentVelo.Z)
	end
end

--dashing--

function CharacterController:_dash()
	--	local moveDir = self.HRP.CFrame:VectorToObjectSpace(self.Humanoid.MoveDirection)

	--insert some guard clauess ig idk

	if tick() - self.ParkourConfig.dashTick < self.ParkourConfig.dashCooldown then
		return
	end
	local LinearVelo = Instance.new("LinearVelocity")
	LinearVelo.Attachment0 = self.HRP.RootAttachment
	LinearVelo.MaxForce = 999999
	LinearVelo.Parent = self.HRP

	Debris:AddItem(LinearVelo, self.ParkourConfig.dashDuration)

	self.ParkourConfig.dashTick = tick()
	--lowk horrendous code block lol
	if self.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		--ground dash
		print("groudn dash")
		--	self.HRP.AssemblyLinearVelocity += self.Humanoid.MoveDirection * self.ParkourConfig.dashVelocity
		LinearVelo.VectorVelocity = UtilFunctions.V3Flat(
			self.HRP.AssemblyLinearVelocity + self.Humanoid.MoveDirection * self.ParkourConfig.dashVelocity
		)
	elseif self.Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		--air dash
		print("air dash")
		--		self.HRP.AssemblyLinearVelocity += Camera.CFrame.LookVector * self.ParkourConfig.dashVelocity

		LinearVelo.VectorVelocity = self.HRP.AssemblyLinearVelocity
			+ Camera.CFrame.LookVector * self.ParkourConfig.dashVelocity
	end
end

return CharacterController
