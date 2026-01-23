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
	self.AudioController = Core:Get("AudioController")
	--remotes--
	self.CharacterEvent = self.SharedRemotes:GetEvent("CharacterEvent")

	-- Current local character & components
	self.Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	self.Humanoid = self.Character.Humanoid
	self.HRP = self.Humanoid.RootPart

	self.CharacterLoaded = Signal.new()

	--Janitors--
	self._janitor = Janitor.new()

	LocalPlayer.CharacterAdded:Connect(function(char: Model)
		print(self.Character)
		--	if not self.Character then --makes sure you don't double load. --note: this conditional actually prevented people from reloading their charactercontroller after respawning

		self:SetupCharacter(char)
		--	end
	end)

	self.Enabled = false

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

	self.MultiJump = self._janitor:Add(Signal.new())

	do
		local hrp = self.HRP
		local ao = hrp:FindFirstChild("CameraOrientation") or Instance.new("AlignOrientation")
		ao.Name = "CameraOrientation"
		ao.Attachment0 = hrp.RootAttachment
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.PrimaryAxisOnly = false
		ao.ReactionTorqueEnabled = false
		ao.RigidityEnabled = false
		ao.MaxTorque = 100000000
		ao.Responsiveness = 100
		ao.Parent = hrp
		ao.Enabled = false
		self.CameraOrientation = ao
	end

	self.ParkourConfig = {
		--Movement--
		baseSpeed = 20,
		maxWalkSpeed = 30, --max walkspeed
		runAccel = 10,
		currentMomentum = 0, -- Tracks our "speed bank"
		targetMomentum = 20,
		linearVeloMaxForce = 10000,

		--crouching--
		isCrouching = false,
		crouchHeight = -1.5,
		crouchSpeed = 4, --crouch walkspeed
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
		defaultSlideDuration = 4, --idk if i'm even using ts
		slideMaxCeilingHeight = 3, --ceiling height for someone sliding underneath a surface
		slideSpeedBoost = 15, --velocity increase by sliding

		canSlide = false,
		slideRequestThreshold = 1, -- time window/coyote time for sliding to start
		slideRequestTick = tick(), -- detects the time from the moment someone press downaction. This will be used to determine whether someone can proceed into a slide, or just go into a crouch( or roll maybe)
		--i think it would be cool if I had an auto roll into crouch at certain veritcal velocities
		--it would also be cool to only make it conditional, so straight into crouching at lower velocites and then roll + crouch with higher velocities if the downaction key is still down

		--multi/double jumping
		baseJumpPower = 30,
		currentJumps = 0,
		maxJumps = 2,

		--dashing--
		dashVelocity = 25,
		dashCooldown = 1,
		dashTick = tick(),
		dashDuration = 0.15,

		--gravity--
		baseGravity = 90,
	}

	--ray params--
	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude
	RayParams.FilterDescendantsInstances = { workspace.SpatialQueryBlacklist, self.Character }

	self.ParkourRayParams = RayParams
	self.ParkourStates = self._janitor:AddObject(StateMachine.new()) --state machine
	--state machine for parkour actions like wallrunning, sliding, vaulting, etc
	--state machine has a Destroy method so this should work

	--shortened variables
	local hum = self.Humanoid
	local char = self.Character
	local hrp = self.HRP

	--parkour vars
	local ParkourStates = self.ParkourStates
	local ParkourConfig = self.ParkourConfig

	--setup movement motor--
	local moveVelocity = Instance.new("LinearVelocity")
	moveVelocity.Name = "MovementMotor"
	moveVelocity.Attachment0 = hrp.RootAttachment
	moveVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	moveVelocity.MaxAxesForce = Vector3.new(1, 0, 1) * ParkourConfig.linearVeloMaxForce -- Force on X and Z, 0 on Y
	moveVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	moveVelocity.VectorVelocity = Vector3.zero
	moveVelocity.Parent = hrp
	self.MoveMotor = moveVelocity

	--set up bind actions--
	--setup input management--
	self.InputController:SetActionCallback("UpAction", function(state, inputObj)
		if state == Enum.UserInputState.Begin then
			--slide canceling for bhopping
			if ParkourStates:IsState("Sliding") then
				self:_deactivateSlide()
				--only use slide hop boost here
				self:_slideHop()
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
						self.AudioController:PlayAudio({ Name = "vault", Source = self.Character })
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
			if hum:GetState() == (Enum.HumanoidStateType.Running or Enum.HumanoidStateType.Landed) then
				if moveDir.Magnitude > 0 then
					self:_activateSlide()
				else
					self:_startCrouch()
				end
			elseif hum:GetState() == Enum.HumanoidStateType.Freefall then
				self.ParkourConfig.slideRequestTick = tick() --begins tick logic stuff or whatever
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
	--hum.WalkSpeed = ParkourConfig.baseSpeed
	hum.UseJumpPower = true
	hum.AutoRotate = false --very necessary
	hum.JumpPower = ParkourConfig.baseJumpPower

	workspace.Gravity = ParkourConfig.baseGravity

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
		elseif new == Enum.HumanoidStateType.Landed then
			if not self.InputController:IsActionKeyDown("DownAction") then
				return
			end

			if
				tick() - self.ParkourConfig.slideRequestTick <= self.ParkourConfig.slideRequestThreshold
				and self.Humanoid.MoveDirection.Magnitude > 0
			then
				self:_activateSlide()
			else
				print("ready to crouch")
				self:_startCrouch()
			end
		end
	end)

	self._janitor:Add(RunService.PreRender:Connect(function(dt)
		self:_updateHRPOrientation(dt)
		self:_updateMovement(dt)
		self:_vaultUpdate(dt)
		self:_slideUpdate(dt)
	end))

	self.CharacterLoaded:Fire(char, hum)
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
	local rayDirection = Vector3.yAxis * self.ParkourConfig.slideMaxCeilingHeight -- Check 3 studs up
	local ceilingRay = workspace:Raycast(rayOrigin, rayDirection, self.ParkourRayParams)

	if not ceilingRay then
		self.ParkourConfig.isCrouching = false
		self.Humanoid.WalkSpeed = self.ParkourConfig.baseSpeed
	else
		-- If blocked, stay crouching (you could add an "Auto-Stand" flag here later)
		self.ParkourConfig.isCrouching = true
	end
end

--handles walking movement stuff
function CharacterController:_updateMovement(dt)
	local config = self.ParkourConfig
	local moveMotor = self.MoveMotor
	local moveDir = self.Humanoid.MoveDirection

	if self.ParkourStates:IsState("Sliding") then
		return
	end

	-- REMOVED: No more momentum drift or window checking
	config.currentMomentum = config.maxWalkSpeed
	config.targetMomentum = config.maxWalkSpeed

	local finalTargetSpeed = config.maxWalkSpeed

	if config.isCrouching and not (self.Humanoid:GetState() == Enum.HumanoidStateType.Freefall) then
		finalTargetSpeed = config.crouchSpeed
	end

	local targetVel = moveDir * finalTargetSpeed
	local accel = moveDir.Magnitude > 0 and config.runAccel or 3.5

	moveMotor.VectorVelocity = moveMotor.VectorVelocity:Lerp(targetVel, dt * accel)

	-- Handle HipHeight for crouching
	local targetHeight = config.isCrouching and config.crouchHeight or 0
	self.Humanoid.HipHeight =
		UtilFunctions.Lerp(self.Humanoid.HipHeight, targetHeight, dt * config.crouchTransitionSpeed)

	self.Humanoid.WalkSpeed = 0
end

--controls leaning and root part orientation
function CharacterController:_updateHRPOrientation(dt)
	if self.ParkourStates:IsState("Sliding") then
		local cameraOrientation = self.CameraOrientation
		if cameraOrientation then
			cameraOrientation.Enabled = false
		end
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
		local ao = hrp:FindFirstChild("CamOrientation")
		if ao then
			ao.Enabled = false
		end
		hum.AutoRotate = true
		local cameraOrientation = self.CameraOrientation
		if cameraOrientation then
			cameraOrientation.Enabled = false
		end
		return
	end

	hum.AutoRotate = false

	local _, y, _ = Camera.CFrame:ToOrientation()

	local ao = hrp:FindFirstChild("CamOrientation") or Instance.new("AlignOrientation")
	ao.Name = "CamOrientation"
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.RigidityEnabled = false
	ao.MaxTorque = 1000000
	ao.Responsiveness = 30 -- Smooth but responsive
	ao.Attachment0 = hrp.RootAttachment
	ao.CFrame = CFrame.Angles(0, y, 0)
	ao.Parent = hrp
	ao.Enabled = true
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
	print("slide attempt")
	print(self.Humanoid:GetState())
	print(self.Humanoid.MoveDirection)
	if
		(
			self.Humanoid:GetState() == Enum.HumanoidStateType.Landed
			or self.Humanoid:GetState() == Enum.HumanoidStateType.Running
		) and self.Humanoid.MoveDirection.Magnitude ~= 0
	then
		print("slide trigger")

		self.AudioController:PlayAudio({ Name = "slideenter", Source = self.Character })

		local hum = self.Humanoid
		local hrp = hum.RootPart

		local DownRay = workspace:Raycast(self.HRP.Position, Vector3.yAxis * -5, self.ParkourRayParams)

		if DownRay then
			self.ParkourStates:SetState("Sliding")
			self.ParkourConfig.rotateHRPWithCamera = false
			hum.AutoRotate = false
			--	hum:ChangeState(Enum.HumanoidStateType.PlatformStanding)

			local cameraOrientation = self.CameraOrientation
			if cameraOrientation then
				cameraOrientation.Enabled = false
			end

			--setup align orientation
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

			--change move motor axis limits--
			self.MoveMotor.MaxAxesForce = Vector3.one * self.ParkourConfig.linearVeloMaxForce

			print(self.MoveMotor.VectorVelocity)
		end
	end
end

function CharacterController:_slideUpdate(dt)
	if not self.ParkourStates:IsState("Sliding") then
		return
	end

	local config = self.ParkourConfig
	local hrp = self.HRP
	local hum = self.Humanoid
	local ao = hrp:FindFirstChild("SlideOrientation")
	local RootJoint = hrp.RootJoint
	self.Humanoid.AutoRotate = false

	self.Humanoid.HipHeight = UtilFunctions.Lerp(hum.HipHeight, config.crouchHeight, dt * config.crouchTransitionSpeed)

	local DownRay = workspace:Raycast(self.HRP.Position, Vector3.yAxis * -5, self.ParkourRayParams)

	if DownRay then
		-- Use the Motor's current velocity as the base
		local currentVel = self.MoveMotor.VectorVelocity

		-- Project onto slope (The "Slide" logic)
		local planeVel = currentVel - DownRay.Normal * currentVel:Dot(DownRay.Normal)
		local downhill = -Vector3.yAxis - (-(Vector3.yAxis):Dot(DownRay.Normal) * DownRay.Normal)

		local targetVel = planeVel + downhill

		-- Flat ground friction
		if downhill.Magnitude < 0.1 then
			targetVel *= 0.98
		end

		-- Update the Master Motor
		self.MoveMotor.VectorVelocity = targetVel

		--set the orientation of align orientation

		if targetVel.Magnitude > 0.5 then
			-- We keep Pitch and Roll at 0 to stay upright
			ao.CFrame = CFrame.lookAt(Vector3.zero, targetVel.Unit)
		else
			self:_deactivateSlide()
			self:_startCrouch()
		end
	else
		self:_deactivateSlide()
	end
end

function CharacterController:_deactivateSlide()
	if not self.ParkourStates:IsState("Sliding") then
		return
	end

	self.MoveMotor.MaxAxesForce = Vector3.new(1, 0, 1) * self.ParkourConfig.linearVeloMaxForce

	self.HRP.Transparency = 1

	self.ParkourStates:ClearState()
	self.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
	self.ParkourConfig.rotateHRPWithCamera = self.CameraController.ShiftLockEnabled or false

	-- Disable constraints
	local ao = self.HRP:FindFirstChild("SlideOrientation")
	if ao then
		ao.Enabled = false
	end

	--check ceiling

	local ceilingRay = workspace:Raycast(
		self.HRP.Position,
		Vector3.yAxis * self.ParkourConfig.slideMaxCeilingHeight,
		self.ParkourRayParams
	)

	if ceilingRay then
		self:_startCrouch()
	end
end

function CharacterController:_slideHop()
	--removed mechanic
end
--multi jump--

function CharacterController:_multiJump()
	if self.ParkourConfig.currentJumps < self.ParkourConfig.maxJumps and self.ParkourConfig.currentJumps >= 1 then
		self.MultiJump:Fire()
		local fx = ReplicatedStorage.Assets.Effects.Jump:Clone()
		fx.Parent = workspace.SpatialQueryBlacklist
		local pos = self.HRP.Position - Vector3.yAxis * 2
		local _, y, _ = self.HRP.CFrame:ToOrientation()
		local cf = CFrame.new(pos) * CFrame.Angles(0, y, 0)
		if fx:IsA("Model") then
			fx:PivotTo(cf)
		else
			(fx :: BasePart).CFrame = cf
		end
		UtilFunctions.Emit(fx)
		Debris:AddItem(fx, 2)
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

	if
		tick() - self.ParkourConfig.dashTick < self.ParkourConfig.dashCooldown or self.ParkourStates:IsState("Sliding")
	then
		return
	end

	self.ParkourConfig.dashTick = tick()
	--lowk horrendous code block lol
	if self.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		--ground dash
		print("ground dash")
		--	self.HRP.AssemblyLinearVelocity += self.Humanoid.MoveDirection * self.ParkourConfig.dashVelocity
		self.MoveMotor.VectorVelocity = UtilFunctions.V3Flat(
			self.HRP.AssemblyLinearVelocity + self.Humanoid.MoveDirection * self.ParkourConfig.dashVelocity
		)
	elseif self.Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		--air dash
		print("air dash")
		--		self.HRP.AssemblyLinearVelocity += Camera.CFrame.LookVector * self.ParkourConfig.dashVelocity

		self.MoveMotor.VectorVelocity = self.HRP.AssemblyLinearVelocity
			+ Camera.CFrame.LookVector * self.ParkourConfig.dashVelocity
	end
end

return CharacterController
