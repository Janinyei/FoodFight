local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage.Assets
local SpeedBoost = {}

SpeedBoost.Id = "SpeedBoost"
SpeedBoost.Duration = 8
SpeedBoost.Magnitude = 1.35

function SpeedBoost:Create()
	local part = Assets.Models.BloxyCola:Clone()
	part.Anchored = true
	part.CanCollide = false
	part.Orientation = Vector3.new(0, 0, 90)
	return part
end

function SpeedBoost:OnPickup(plr: Player, pickupManager)
	pickupManager.StatusEffectManager:ApplyEffect(plr, self.Id, self.Duration)
end

return SpeedBoost
