local Blackhole = {}

function Blackhole:PlayKillEffect(data, Core)
	local TargetCharacter = data.TargetCharacter
	local AudioController = Core:Get("AudioController")
	
    local TweenService = game:GetService("TweenService")
    local UtilFunctions = require(game.ReplicatedStorage.Modules.Utils.Functions)

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

	AudioController:PlayAudio({
		Name = "blackhole_warp",
		Source = TargetCharacter.HumanoidRootPart,
	})
	DragAP.Enabled = true

	local BlackholeVFX = game.ReplicatedStorage.Assets.KillEffects.Blackhole.Blackhole:Clone()

	BlackholeVFX.Parent = workspace

	BlackholeVFX.Position = TargetPos


	task.delay(Duration, function()
		
		BlackholeVFX:Destroy()
	end)

    task.spawn(function()
        local StartTime = os.clock()
        local Duration = 4 -- Match your blackhole duration
        
        while TargetCharacter and TargetCharacter.Parent do
            local Elapsed = os.clock() - StartTime
            local Alpha = math.clamp(Elapsed / 2, 0, 1) -- Moves from 0 to 1
            
            -- Use an Easing function for a "vacuum" feel (starts slow, ends fast)
            local CurvedAlpha = Alpha
            
            local currentScale = UtilFunctions.Lerp(1, 0.05, CurvedAlpha)
            TargetCharacter:ScaleTo(currentScale)
            
            if Alpha >= 1 then break end
            task.wait() -- Runs every frame
        end
    end)
end

return Blackhole
