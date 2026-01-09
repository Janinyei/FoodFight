--purpsoe: replaces default Animate script functionality to handle animations used on the character
--janin 12/26/25

--note: ngl idk what i'm doing

--Services--

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Modules--
local Modules = ReplicatedStorage.Modules

--Imports--
local UtilFunctions = require(Modules.Utils.Functions)
local AnimationController = {}

function AnimationController:Init(Core)
	self.Animations = {

		--movement--

		["idle"] = {
			id = "106297999323121",
			priority = Enum.AnimationPriority.Idle,
		},

		["walk"] = {
			id = "88434087068260",
			priority = Enum.AnimationPriority.Movement,
			looped = true,
		},

		["run"] = {
			id = "127722194358189",
			priority = Enum.AnimationPriority.Movement,
			looped = true,
		},
		["jumpLeft"] = {
			id = "92167310455994",
			priority = Enum.AnimationPriority.Movement,
		},

		["jumpRight"] = {
			id = "118422222797700",
			priority = Enum.AnimationPriority.Movement,
		},

		["fall"] = {
			id = "111322421652047",
			priority = Enum.AnimationPriority.Movement,
			looped = true,
		},

		["crouchWalk"] = {
			id = "74271103529901",
			priority = Enum.AnimationPriority.Movement,
			looped = true,
		},

		--parkour--

		["vault"] = {
			id = "89679420163882",
			priority = Enum.AnimationPriority.Action,
		},

		["slideEnter"] = {
			id = "109806884429456",
			priority = Enum.AnimationPriority.Action2,
		},

		["slide"] = {
			id = "125887876454569",
			priority = Enum.AnimationPriority.Action,
			looped = true,
		},

		["flail"] = {
			id = "106907468985691",
			priority = Enum.AnimationPriority.Action,
			looped = true,
		},

		["roll"] = {
			id = "96639831168821",
			priority = Enum.AnimationPriority.Action,
		},

		--emotes--
	}

	self.LoadedAnimTracks = {} -- table to place all loaded anim tracks

	self.CurrentMovementAnim = nil --current movement anim

	self.CharacterController = Core:Get("CharacterController")
	self.AudioController = Core:Get("AudioController")

	self.Character = nil
	self.Humanoid = nil
end

function AnimationController:Start()
	self.CharacterController.CharacterLoaded:Connect(function(char, hum)
		print(char.Name)
		self.Character = char
		self.Humanoid = hum

		self:_handleMovementAnims()

		--load all animations--

		for trackName, animData in self.Animations do
			print(animData)
			local Animation = Instance.new("Animation")
			Animation.AnimationId = "rbxassetid://" .. animData.id
			Animation.Name = trackName

			local animTrack = hum.Animator:LoadAnimation(Animation)
			animTrack.Priority = animData.Priority or Enum.AnimationPriority.Action
			animTrack.Looped = animData.looped or false

			self.LoadedAnimTracks[trackName] = animTrack
		end
	end)
end

function AnimationController:PlayAnim(animName: string, fadeTime: number)
	local targetTrack = self.LoadedAnimTracks[animName]
	if not targetTrack then
		warn("target track doesn't exist")
		return
	end
	--	print("playing "..animName)
	targetTrack:Play(fadeTime or 0.2)
	
end

function AnimationController:StopAnim(animName: string)
	local targetTrack = self.LoadedAnimTracks[animName]
	if not targetTrack then
		warn("target track doesn't exist")
		return
	end
	targetTrack:Stop()
end

--plays anim only if it's not playing
function AnimationController:SafePlay(animName: string, fadeTime: number)
	local targetTrack: AnimationTrack = self:GetTrack(animName)

	if not targetTrack.IsPlaying then
		self:PlayAnim(animName, fadeTime)
	end
end

function AnimationController:GetTrack(animName: string)
	return self.LoadedAnimTracks[animName]
end

--priv--

function AnimationController:_handleMovementAnims()
	if not (self.Character and self.Humanoid) then
		return
	end

	local hum = self.Humanoid
	local ParkourStates = self.CharacterController.ParkourStates
	local Config = self.CharacterController.ParkourConfig

	--jump switch--
	local jumpSwitch = true
	local jumpTick = tick()

	local function handleJump()
		jumpSwitch = not jumpSwitch
		jumpTick = tick()

		self.AudioController:PlayAudio({Name = "jump", Source = self.Character})


		if jumpSwitch then
			--play left anim

			self:_playMovementAnim("jumpLeft", false)
		else
			--play right anim
			self:_playMovementAnim("jumpRight", false)
		end
	end
	--Humanoid State Events (Jumping/Falling)
	hum.StateChanged:Connect(function(old, new)
		-- We only play these if we AREN'T in a special parkour state like Vaulting

		if new == Enum.HumanoidStateType.Jumping then
			handleJump()
		elseif new == Enum.HumanoidStateType.Landed then
			self:StopAnim("vault")
		end
	end)

	self.CharacterController.MultiJump:Connect(function()
		handleJump()
	end)

	--parkour state events
	ParkourStates.StateChanged:Connect(function(old, new)
		print(old, new)
		if new == "Vaulting" then
			self:PlayAnim("vault", false, 0.1)
		elseif new == "Sliding" then
			self:PlayAnim("slideEnter", 0.1)
			self:PlayAnim("slide", 0.1)
		end


		if old == "Sliding" then
			self:StopAnim("slide")
			self:StopAnim("slideEnter")
		end
	end)

	--cleanup ig
	hum.Died:Connect(function()
		for _, track in pairs(self.LoadedAnimTracks) do
			track:Stop(0)
		end
		self.CurrentMovementAnim = nil
	end)

	--Animation Loop(primarily for movement)
	RunService.PreRender:Connect(function(dt)
		--if ParkourStates:IsState("Vaulting") or ParkourStates:IsState("Sliding") then return end

		if ParkourStates:IsState("Sliding") then
			self:_playMovementAnim("slide", true, 0.3)
			return
		end

		local hState = hum:GetState()
		local speed = UtilFunctions.V3Flat(hum.RootPart.AssemblyLinearVelocity).Magnitude

		if hState == Enum.HumanoidStateType.Freefall and tick() - jumpTick > 0.35 then
			self:_playMovementAnim("fall", true, 0.15)
		end

		--Crouch Movement
		if hState == Enum.HumanoidStateType.Running or hState == Enum.HumanoidStateType.Landed then
			-- Handle Crouching First
			if Config.isCrouching then
				if speed > 0.5 then
					self:_playMovementAnim("crouchWalk", true)
					self:GetTrack("crouchWalk"):AdjustSpeed(speed * 0.15)
				else
					-- You'll need a crouchIdle id! If not, walk at 0 speed looks weird
					self:_playMovementAnim("crouchWalk", true)
					self:GetTrack("crouchWalk"):AdjustSpeed(0)
				end
				return
			end

			-- Handle Stand/Walk/Run
			if speed >= 22 then -- Momentum/Sprint
				self:_playMovementAnim("run", true)
				self:GetTrack("run"):AdjustSpeed(speed / 30)
			elseif speed > 0.5 then
				self:_playMovementAnim("walk", true)
				self:GetTrack("walk"):AdjustSpeed(speed / 16)
			else
				self:_playMovementAnim("idle", true)
			end
		end
	end)
end

--handles switching in between movement anim
function AnimationController:_playMovementAnim(animName: string, safe: boolean, fadeTime: number?)
	if self.CurrentMovementAnim == self:GetTrack(animName) then
		return
	end

	if self.CurrentMovementAnim then
		self.CurrentMovementAnim:Stop()
		self.CurrentMovementAnim = nil
	end

	self.CurrentMovementAnim = self:GetTrack(animName)

	if safe then
		self:SafePlay(animName, fadeTime)
	else
		self:PlayAnim(animName, fadeTime)
	end
end

return AnimationController
