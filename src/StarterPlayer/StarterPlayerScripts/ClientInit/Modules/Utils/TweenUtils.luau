local TweenService = game:GetService("TweenService")
local TweenUtils = {}


--Uses bouncy hovering for buttons with UI Scale objects
TweenUtils.BouncyHoverWithUIScale = function(UIElement : GuiObject, UIScale : UIScale, Diff : number)
    
    local DefaultScale = 1
  

    local Info = TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out) 
    local GrowTween = TweenService:Create(UIScale, Info , {Scale = DefaultScale + Diff})
    local ShrinkTween = TweenService:Create(UIScale, Info, {Scale = DefaultScale})

        UIElement.MouseEnter:Connect(function()
           GrowTween:Play()
       end)
    
       UIElement.MouseLeave:Connect(function()
           ShrinkTween:Play()
     end)
end

--Be sure that these GuiObjects have UIScales
TweenUtils.GrowOnHover =  function(UIElement : GuiObject, UIScale : UIScale, Diff :number, TwnInfo : TweenInfo)

    local DefaultScale = 1
    local GrowTween = TweenService:Create(UIScale, TwnInfo , {Scale = DefaultScale + Diff})
    local ShrinkTween = TweenService:Create(UIScale, TwnInfo, {Scale = DefaultScale})

    UIElement.MouseEnter:Connect(function()
        GrowTween:Play()
    end)

    UIElement.MouseLeave:Connect(function()
        ShrinkTween:Play()
    end)
end


--Rotates on hover
TweenUtils.RotateOnHover = function(UIElement : GuiObject, GoalRot, TwnInfo)
        local DefaultRotation = UIElement.Rotation

        local RotateTween = TweenService:Create(UIElement, TwnInfo, {Rotation = GoalRot})
        local ResetTween = TweenService:Create(UIElement, TwnInfo, {Rotation = DefaultRotation})
       UIElement.MouseEnter:Connect(function()
        print("rotating")
          RotateTween:Play()
        end)
    
      UIElement.MouseLeave:Connect(function()
          ResetTween:Play()
        end)
end

--handles button tweening
TweenUtils.ButtonClickTween = function(UIElement : ImageButton | TextButton, UIScale : UIScale, Diff : number, callback : () -> any)
    local DefaultScale = UIScale.Scale

    local Info = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut) 


    UIElement.MouseButton1Down:Connect(function()
     local DownTween = TweenService:Create(UIScale, Info , {Scale = DefaultScale - Diff })
     DownTween:Play()
    end)


    UIElement.MouseButton1Up:Connect(function()

        
        local UpTween = TweenService:Create(UIScale, Info , {Scale =  DefaultScale})
        UpTween:Play()

        if callback then 
            callback()
        end

    end)
end


--Tween Bar

TweenUtils.TweenBar = function(UIElement : GuiObject, Percentage : number, Duration : number)
    local Info = TweenInfo.new(Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    local BarTween = TweenService:Create(UIElement, Info , {Size = UDim2.fromScale(Percentage, 1)})
    BarTween:Play()
end


TweenUtils.CustomTween = function()
    
end

return TweenUtils