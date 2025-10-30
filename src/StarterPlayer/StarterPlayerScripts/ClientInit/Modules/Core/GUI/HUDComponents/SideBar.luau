--purpose: controls UI in the sidebar (pretty much stats UI controller)
--janin 10/30/25

local SideBar = {}

--Helpers--
local function GetProgressBarSize( Bar : GuiObject ,Exp : number, MaxExp : number)
    return UDim2.fromScale(Exp/MaxExp, Bar.Size.Y.Scale)
end

function SideBar:Init(Core)
    self.MainUI = game.Players.LocalPlayer.PlayerGui.HUD.SideBar  
    self.ClientDataController = Core:Get("ClientDataController")

    --Sidebar UI
    self.Coins = self.MainUI.Coins
    self.Progression = self.MainUI.Progression
    self.ProgressBar = self.Progression.ProgressBar
    self.Rank = self.Progression.Rank
    self.Level = self.Progression.LevelNum


    --init UI based on initial values

    
    
    self.ClientDataController.CurrencyChanged:Connect(function(Currency)
        print("COINS CHANGED")
        local Coins = Currency.Coins
        self.Coins.Amount.Text = tostring(Coins)
    end)
    
    self.ClientDataController.ProgressionChanged:Connect(function(ProgressionData, MaxExp)
        self.ProgressBar.Progress.Size = GetProgressBarSize(self.ProgressBar.Progress, ProgressionData.Exp, MaxExp)
        self.Rank.Text = ProgressionData.Rank
        self.Level.Text = "Lvl " .. ProgressionData.Level

    end)
   
end

function SideBar:Start()

end




return SideBar