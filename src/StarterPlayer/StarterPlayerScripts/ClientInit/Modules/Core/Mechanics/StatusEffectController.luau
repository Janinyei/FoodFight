--Purpose: Handles clint status effects
--Note: Listens for status effect changes from server

local StatusEffectController = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Modules.Utils.Signal)
local Janitor = require(ReplicatedStorage.Modules.Utils.Janitor)
local SpeedLines = require(ReplicatedStorage.Modules.Effects.SpeedLines)
local ScreenEffects = require(ReplicatedStorage.Modules.Effects.ScreenEffects)

function StatusEffectController:Init(Core)
	self.Core = Core
	self.StatusEffectSignal = Signal.new()
	self.Effects = {}
	self.CharacterController = Core:Get("CharacterController")
	self.StatusEffectEvent = Core:Get("SharedRemotes"):GetEvent("StatusEffectEvent")

	self.EffectConfig = {
		SpeedBoost = {
			Multiplier = 1.35,
			SpeedLinesRate = 160,
			VignetteColor = Color3.fromRGB(0, 128, 255),
			VignetteTargetTransparency = 0.5,
			VignetteInitialTransparency = 0.6,
		},
	}

	self._defaultParkour = nil
	self._speedBoostVfxJanitor = nil
	self._speedBoostVfxCharacter = nil

	self.CharacterController.CharacterLoaded:Connect(function()
		self:_captureDefaults()
		for _, effectName in ipairs(self.Effects) do
			self:_handleStatusEffect(effectName, true)
		end
	end)
	self:_captureDefaults()

	self.StatusEffectEvent:Connect(function(effectName, applied)
		if applied then
			if table.find(self.Effects, effectName) == nil then
				table.insert(self.Effects, effectName)
			end
		else
			local idx = table.find(self.Effects, effectName)
			if idx then
				table.remove(self.Effects, idx)
			end
		end

		self.StatusEffectSignal:Fire(effectName, applied)
		self:_handleStatusEffect(effectName, applied)
	end)
end

function StatusEffectController:_handleStatusEffect(effectName, applied)
	if effectName == "Ragdoll" and applied then
		print("ragdoll")
		return
	end

	if effectName == "SpeedBoost" then
		self:_applySpeedBoost(applied)
	end
end

function StatusEffectController:_captureDefaults()
	local cfg = self.CharacterController and self.CharacterController.ParkourConfig
	if not cfg then
		return
	end

	self._defaultParkour = {
		baseSpeed = cfg.baseSpeed,
		maxWalkSpeed = cfg.maxWalkSpeed,
		crouchSpeed = cfg.crouchSpeed,
	}
end

function StatusEffectController:_applySpeedBoost(applied: boolean)
	local cfg = self.CharacterController.ParkourConfig
	local defaults = self._defaultParkour
	if not defaults then
		self:_captureDefaults()
		defaults = assert(self._defaultParkour)
	end

	local multiplier = self.EffectConfig.SpeedBoost.Multiplier

	if applied then
		cfg.baseSpeed = defaults.baseSpeed * multiplier
		cfg.maxWalkSpeed = defaults.maxWalkSpeed * multiplier
		cfg.crouchSpeed = defaults.crouchSpeed * multiplier
	else
		cfg.baseSpeed = defaults.baseSpeed
		cfg.maxWalkSpeed = defaults.maxWalkSpeed
		cfg.crouchSpeed = defaults.crouchSpeed
	end

	cfg.targetMomentum = cfg.maxWalkSpeed
	self:_setSpeedBoostVfxEnabled(applied)
end

function StatusEffectController:_setSpeedBoostVfxEnabled(enabled: boolean)
	if not enabled then
		if self._speedBoostVfxJanitor then
			self._speedBoostVfxJanitor:Cleanup()
			self._speedBoostVfxJanitor = nil
			self._speedBoostVfxCharacter = nil
		end
		return
	end

	local character, _, hrp = self.CharacterController:GetCharacter()
	if self._speedBoostVfxJanitor and self._speedBoostVfxCharacter == character then
		return
	end

	if self._speedBoostVfxJanitor then
		self._speedBoostVfxJanitor:Cleanup()
	end

	local conf = self.EffectConfig.SpeedBoost
	local vfxJanitor = Janitor.new()

	vfxJanitor:Add(assert(SpeedLines:Play(conf.SpeedLinesRate)), "Cleanup")
	vfxJanitor:Add(
		assert(ScreenEffects.Vignette(conf.VignetteColor, conf.VignetteTargetTransparency, conf.VignetteInitialTransparency)),
		true
	)

	local trail = ReplicatedStorage.Assets.Effects.SpeedTrail:Clone()
	trail.Anchored = false
	trail.CanCollide = false
	trail.CFrame = hrp.CFrame
	trail.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = trail
	weld.Parent = trail

	vfxJanitor:Add(trail, "Destroy")

	self._speedBoostVfxJanitor = vfxJanitor
	self._speedBoostVfxCharacter = character
end

--can check if you or someone else has an effect
function StatusEffectController:HasEffect(player, effectName: string)
	return (player ~= LocalPlayer) and self.StatusEffectEvent:Invoke(20, "HasEffect", effectName)
		or (table.find(self.Effects, effectName) ~= nil)
end

function StatusEffectController:OnStatusEffectApplied(callback)
	return self.StatusEffectSignal:Connect(callback)
end

return StatusEffectController
