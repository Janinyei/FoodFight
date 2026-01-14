local Blackhole = {}

function Blackhole:PlayKillEffect(data)
	local TargetPlr = data.TargetPlayer

	local TargetCharacter = TargetPlr.Character

	local Duration = 4

	local TargetPos = TargetCharacter.HumanoidRootPart.Position + Vector3.yAxis * 10

	local FloatAttachment = Instance.new("Attachment")

	FloatAttachment.Parent = TargetCharacter.Torso

	local DragAP = Instance.new("AlignPosition")

	DragAP.MaxAxesForce = Vector3.new(0, 10000000, 0)

	DragAP.Parent = FloatAttachment

	DragAP.Position = TargetPos

	DragAP.ForceLimitMode = Enum.ForceLimitMode.PerAxis

	DragAP.Mode = Enum.PositionAlignmentMode.OneAttachment

	DragAP.Attachment0 = FloatAttachment

	--  DragAP.RigidityEnabled = true

	DragAP.Enabled = true

	local BlackholeVFX = game.ReplicatedStorage.Assets.KillEffects.Blackhole.Blackhole:Clone()

	BlackholeVFX.Parent = workspace

	BlackholeVFX.Position = TargetPos

	task.delay(Duration, function()
		DragAP:Destroy()

        
		BlackholeVFX:Destroy()
	end)
end

return Blackhole
