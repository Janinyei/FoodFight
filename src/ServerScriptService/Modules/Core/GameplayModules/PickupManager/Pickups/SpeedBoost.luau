local SpeedBoost = {}

SpeedBoost.Id = "SpeedBoost"
SpeedBoost.Duration = 8
SpeedBoost.Magnitude = 1.35

function SpeedBoost:Create()
	local part = Instance.new("Part")
	part.Name = "EnergyCan"
	part.Size = Vector3.new(1.2, 1.6, 1.2)
	part.Shape = Enum.PartType.Cylinder
	part.Anchored = true
	part.CanCollide = false
	part.Color = Color3.fromRGB(0, 170, 255)
	part.Material = Enum.Material.Neon
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Orientation = Vector3.new(0, 0, 90)
	return part
end

function SpeedBoost:OnPickup(plr: Player, pickupManager)
	pickupManager.StatusEffectManager:ApplyEffect(plr, self.Id, self.Duration)
end

return SpeedBoost
