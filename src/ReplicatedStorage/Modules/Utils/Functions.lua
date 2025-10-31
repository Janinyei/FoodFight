local RunService = game:GetService("RunService")
return {
    Raycast = function(Origin, Direction, Parameters)
        Parameters = Parameters or RaycastParams.new()
        return workspace:Raycast(Origin, Direction, Parameters)
    end,
    
    GetGroundPos = function(Position)
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Include
        Params.FilterDescendantsInstances = {workspace.Map}
        
        local Raycast = workspace:Raycast(Position, Vector3.new(0, -100, 0), Params)
        if Raycast then
            return Raycast.Position
        end
        return Vector3.new(Position.X, Position.Y, Position.Z)
    end,

    Emit = function(Obj)
        for _, Child in Obj:GetDescendants() do
            if Child:IsA("ParticleEmitter") then
                Child:Emit(20)
            end
        end
    end,

    Tween = function(Instance, Properties, TweenInfo, Callback)
        local TweenService = game:GetService("TweenService")
        TweenInfo = TweenInfo or TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local Tween = TweenService:Create(Instance, TweenInfo, Properties)
        Tween:Play()
        if Callback then
            Tween.Completed:Connect(Callback)
        end
        return Tween
    end,

    TweenModel = function(Model, StartPos, TPos, Duration, Callback)
        Duration = Duration or 0.5
        
        Model:PivotTo(CFrame.new(StartPos))
        
        local StartTime = tick()
        local Connection
        Connection = RunService.Heartbeat:Connect(function()
            local Elapsed = tick() - StartTime
            local Alpha = math.clamp(Elapsed / Duration, 0, 1)
            
            local CurrentPos = StartPos:lerp(TPos, Alpha)
            Model:PivotTo(CFrame.new(CurrentPos))
            
            if Alpha >= 1 then
                Connection:Disconnect()
                if Callback then
                    Callback()
                end
            end
        end)
        
        return Connection
    end
}