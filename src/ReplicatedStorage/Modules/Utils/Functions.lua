
--note: I would prefer these functions to be their own separate modules in a "Functions" folder. Makes it easier to see from the outside.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

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

    Emit = function(Obj: Model | BasePart)
        for _, Particle in Obj:GetDescendants() do
            if Particle:IsA("ParticleEmitter") then
                task.delay(Particle:GetAttribute("EmitDelay") or 0.001, function()
                    Particle:Emit(Particle:GetAttribute("EmitCount") or 10)
                end)
            end
        end
    end,

    Tween = function(Instance: Model | BasePart, Properties, Info, Callback)
        Info = Info or TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        if Instance:IsA("Model") then
            local Parts = {}
            for _, Descendant in Instance:GetDescendants() do
                if Descendant:IsA("BasePart") then
                    table.insert(Parts, Descendant)
                end
            end
            
            local Tweens = {}
            for _, Part in Parts do
                local Tween = TweenService:Create(Part, Info, Properties)
                Tween:Play()
                table.insert(Tweens, Tween)
            end
            
            if Callback then
                local Cnt = 0
                local T = #Tweens
                for _, Tween in Tweens do
                    Tween.Completed:Once(function()
                        Cnt = Cnt + 1
                        if Cnt >= T then
                            Callback()
                        end
                    end)
                end
            end
            
            return Tweens
        else
            local Tween = TweenService:Create(Instance, Info, Properties)
            Tween:Play()
            if Callback then
                Tween.Completed:Once(Callback)
            end
            return Tween
        end
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
    end,

    

    FindCharacter = function(obj : Instance)
        if obj and obj:FindFirstAncestorWhichIsA("Model") then
            local character = obj:FindFirstAncestorOfClass("Model")
            local isPlayer = Players:GetPlayerFromCharacter(character)
            if character and character:FindFirstChild("Humanoid") then
                return character, isPlayer
            end
        end
    end,


   Lerp = function (a, b, t) return a + (b - a) * t end
}
