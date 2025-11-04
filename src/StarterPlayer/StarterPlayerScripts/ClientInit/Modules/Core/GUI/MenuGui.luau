--Purpose: controls the main menu screen and its components
--Note: ngl this is probably gonna be a long script so apologies in advance
--janin 11/2/25

local MenuGui = {}
--Services--
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local ReplicatedStorage = game:GetService("ReplicatedStorage")



--imports--
local ItemIndex = require(ReplicatedStorage.Modules.Info.ItemIndex)

function MenuGui:Init(Core)
	self.MenuScreen = PlayerGui.Menu
	self.ClientDataController = Core:Get("ClientDataController")
    self.ScreenGuiController = Core:Get("ScreenGuiController")
	self.TweenUtils = Core:Get("TweenUtils")
    self.MouseController = Core:Get("MouseController")

	--loads menu components--
	self:InitProgressionGui()
	self:InitCurrencyGui()
	self:InitBottomFrame()
	self:InitInventoryGui()
end

function MenuGui:Start() end

--Progression Gui--
function MenuGui:InitProgressionGui()
	self.ProgressionGui = self.MenuScreen.Container.ProgressionFrame

	local ProgressionGui = self.ProgressionGui
	local ProgressBarContainer = ProgressionGui.ProgressBarContainer
	local ProgressBar = ProgressBarContainer.ProgressBar

	self.ClientDataController.ProgressionChanged:Connect(function(ProgressionData)
		local MaxExp = math.ceil((ProgressionData.Level / 2) * math.log10((ProgressionData.Level + 1) ^ 2) * 100 + 100) --just copied the formula
		--level text
		ProgressionGui.LevelNum.Text = tostring(ProgressionData.Level)

		--rank text
		ProgressionGui.Rank.Text = ProgressionData.Rank

		--exp bar text and sizing
		ProgressBarContainer.ExpAmount.Text = tostring(ProgressionData.Exp) .. " / " .. tostring(MaxExp)

		local ProgressPercent = ProgressionData.Exp / MaxExp
		-- ProgressBar.Size = UDim2.fromScale(ProgressPercent, 1)
		self.TweenUtils.TweenBar(ProgressBar, ProgressPercent, 0.5)
	end)
end

--Currency Gui--
function MenuGui:InitCurrencyGui()

    self.CurrencyGui = self.MenuScreen.Container.CurrencyFrame
    local CurrencyGui = self.CurrencyGui
    
	self.ClientDataController.CurrencyChanged:Connect(function(CurrencyData)
		CurrencyGui.Coins.Amount.Text = tostring(CurrencyData.Coins)
		CurrencyGui.Gems.Amount.Text = tostring(CurrencyData.Gems)
	end)

    for _, UIFrame in self.CurrencyGui:GetChildren() do
        if UIFrame:FindFirstChild("BuyMore") then
            local BuyMoreFrame = UIFrame.BuyMore
            self.TweenUtils.GrowOnHover(
                BuyMoreFrame,
                BuyMoreFrame.UIScale,
                0.1,
                TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            )

            self.TweenUtils.ButtonClickTween(BuyMoreFrame.Button, BuyMoreFrame.UIScale, 0.05, function()
                print("Buy more " .. UIFrame.Name .. " clicked")
                --open store screen
                self.ScreenGuiController:SetScreen("Store")
            end)
        end
    end
end

--Bottom Frame
function MenuGui:InitBottomFrame()
	self.BottomFrame = self.MenuScreen.Container.BottomFrame
	local PlayButton = self.BottomFrame.PlayButton
	local StoreButton = self.BottomFrame.StoreButton
	local SettingsButton = self.BottomFrame.SettingsButton

	for _, UIFrame in self.BottomFrame:GetChildren() do
		if UIFrame:IsA("GuiObject") and UIFrame:FindFirstChild("UIScale") then
			self.TweenUtils.GrowOnHover(
				UIFrame,
				UIFrame.UIScale,
				0.1,
				TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
			)

			self.TweenUtils.ButtonClickTween(UIFrame.Button, UIFrame.UIScale, 0.05, function()
				print(UIFrame.Name .. " clicked")
				--button functionality goes here--
				if UIFrame == PlayButton then
					self.ScreenGuiController:SetScreen("HUD")
                    self.MouseController:Lock()
				elseif UIFrame == StoreButton then
                    self.ScreenGuiController:SetScreen("Store")
				elseif UIFrame == SettingsButton then
					self.ScreenGuiController:SetScreen("Settings")
				end
			end)
		end
	end
end

function MenuGui:InitInventoryGui()
	self.InventoryGui = self.MenuScreen.Container.InventoryFrame
	local InventoryGui = self.InventoryGui

	local TabContainer = InventoryGui.TabContainer
	local PageContainer = InventoryGui.PageContainer
	local UIPageLayout = PageContainer.UIPageLayout

	--navigation logic--

	for _, Button in TabContainer:GetChildren() do
		if Button:IsA("TextButton") or Button:IsA("ImageButton") then
			local TargetPage = PageContainer:FindFirstChild(Button.Name)
			Button.MouseButton1Click:Connect(function()
				if TargetPage then
					UIPageLayout:JumpTo(TargetPage)
                    Button.BorderStroke.Color = Color3.fromRGB(255,255,255)

                    --change other buttons back
                    for _, OtherButton in TabContainer:GetChildren() do
                        if (OtherButton:IsA("TextButton") or OtherButton:IsA("ImageButton")) and OtherButton ~= Button then
                            OtherButton.BorderStroke.Color = Color3.fromRGB(50,50,50)
                        end
					end
				end
			end)
		end
	end

	--load items in inventory pages--
	local InventoryItemTemplate = InventoryGui.PageContainer.Food.Burger--item template for all of the inventory
	local ItemTooltipUI = PlayerGui.Tooltip --tooltip UI
	
	--use one tooltip UI for every item
	for _, Category in ItemIndex do
		for _, ItemData in Category do
			local ItemFrame = InventoryItemTemplate:Clone()
			ItemFrame.Parent = PageContainer[ItemData.Type]
			--events--

			ItemFrame.MouseEnter:Connect(function()
				--show tooltip
				ItemTooltipUI.Enabled = true
		
			end)

			ItemFrame.MouseLeave:Connect(function()
				--hide tooltip
				ItemTooltipUI.Enabled = false
				--tween frame--
			end)

			ItemFrame.MouseMoved:Connect(function(x, y)
				--move tooltip
				ItemTooltipUI.Container.Position = UDim2.fromOffset(x,y)
			end)
		end
	end
end

return MenuGui
