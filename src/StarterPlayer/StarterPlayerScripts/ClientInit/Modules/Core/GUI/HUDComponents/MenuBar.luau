local MenuBar = {}
--Variables--
local LocalPlayer = game.Players.LocalPlayer

function MenuBar:Init(Core)
    self.BarUI = LocalPlayer.PlayerGui.HUD.MenuBar
    self.TweenUtils = Core:Get("TweenUtils")
end

function MenuBar:Start()
    for _, UIFrame in self.BarUI:GetChildren() do 
        if UIFrame:IsA("Frame") then
        self.TweenUtils.BouncyHoverWithUIScale(UIFrame, UIFrame.Button.UIScale, 0.15)
        self.TweenUtils.RotateOnHover(UIFrame.Button, 15 , TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
        self.TweenUtils.ButtonClickTween(UIFrame.Button, UIFrame.Button.UIScale, 0.1)
        end
    end
end


function MenuBar:Show()
    self.BarUI.Visible = true
end


function MenuBar:Hide()
    self.BarUI.Visible = false
end


return MenuBar


