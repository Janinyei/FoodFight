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
local PlayerScripts = LocalPlayer.PlayerScripts
local ClientUtils = PlayerScripts.ClientInit.Modules.Utils
local ItemIndex = require(ReplicatedStorage.Modules.Info.ItemIndex)
local RarityIndex = require(ReplicatedStorage.Modules.Info.RarityIndex)
local TweenUtils = require(ClientUtils.TweenUtils)


function MenuGui:Init(Core)
	self.MenuScreen = PlayerGui.Menu
	self.ClientDataController = Core:Get("ClientDataController")
    self.ScreenGuiController = Core:Get("ScreenGuiController")
    self.MouseController = Core:Get("MouseController")
    self.CharacterEvent = Core:Get("SharedRemotes"):GetEvent("CharacterEvent")
	self.InventoryEvent = Core:Get("SharedRemotes"):GetEvent("InventoryEvent")

	--loads menu components--
--	self:InitProgressionGui()
--	self:InitCurrencyGui()
--	self:InitBottomFrame()
--	self:InitInventoryGui()
end

function MenuGui:Start() end

--Progression Gui--
function MenuGui:InitProgressionGui()
	self.ProgressionGui = self.MenuScreen.Container.ProgressionContainer

	local ProgressionGui = self.ProgressionGui
	local ProgressBarContainer = ProgressionGui.Progression.ProgressBarContainer
	local ProgressBar = ProgressBarContainer.ProgressBar
	local PlayerName = self.ProgressionGui.PlayerName

	self.ClientDataController.ProgressionChanged:Connect(function(ProgressionData)
		local MaxExp = math.ceil((ProgressionData.Level / 2) * math.log10((ProgressionData.Level + 1) ^ 2) * 100 + 100) --just copied the formula
		--level text
		ProgressionGui.Progression.LevelNum.Text = tostring(ProgressionData.Level)

		--rank text
		ProgressionGui.Progression.Rank.Text = ProgressionData.Rank

		--exp bar text and sizing
		ProgressBarContainer.ExpAmount.Text = tostring(ProgressionData.Exp) .. " / " .. tostring(MaxExp)

		local ProgressPercent = ProgressionData.Exp / MaxExp
		-- ProgressBar.Size = UDim2.fromScale(ProgressPercent, 1)
		TweenUtils.TweenBar(ProgressBar, ProgressPercent, 0.5)
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
            TweenUtils.GrowOnHover(
                BuyMoreFrame,
                BuyMoreFrame.UIScale,
                0.1,
                TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            )

            TweenUtils.ButtonClickTween(BuyMoreFrame.Button, BuyMoreFrame.UIScale, 0.05, function()
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
			TweenUtils.GrowOnHover(
				UIFrame,
				UIFrame.UIScale,
				0.1,
				TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
			)

			TweenUtils.ButtonClickTween(UIFrame.Button, UIFrame.UIScale, 0.05, function()
			
				--button functionality goes here--
				if UIFrame == PlayButton then
                    self.CharacterEvent:Invoke(8, "Spawn")
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
	self.InventoryGui = self.MenuScreen.Container.InventoryContainer
	local InventoryGui = self.InventoryGui

	local TabContainer = InventoryGui.Topbar
	local PageContainer = InventoryGui.PageContainer
	local UIPageLayout = PageContainer.UIPageLayout



	--navigation logic--

	for _, Button in TabContainer:GetChildren() do
		if Button:IsA("Frame") then
			local TargetPage = PageContainer:FindFirstChild(Button.Name)
			Button.ImageButton.MouseButton1Click:Connect(function()
				if TargetPage then
					UIPageLayout:JumpTo(TargetPage)
                    Button.UIStroke.Color = Color3.fromRGB(255,255,255)

                    --change other buttons back
                    for _, OtherButton in TabContainer:GetChildren() do
                        if OtherButton:IsA("Frame") and OtherButton ~= Button then
                            OtherButton.UIStroke.Color = Color3.fromRGB(50,50,50)
                        end
					end
				end
			end)
		end
	end

	--load items in inventory pages--
	local InventoryItemTemplate = InventoryGui.PageContainer.Food.ItemFrame--item template for all of the inventory
	local ItemTooltipUI = PlayerGui.Tooltip --tooltip UI
	
	--use one tooltip UI for every item
	for _, Category in ItemIndex do
		for ItemName, ItemData in Category do
			local ItemFrame = InventoryItemTemplate:Clone()
			ItemFrame.Visible = true
			ItemFrame.Name = ItemName
			ItemFrame.Parent = PageContainer[ItemData.Type]
			ItemFrame.LayoutOrder = ItemData.Order

			--display item image
			if ItemData.ImageId then
			ItemFrame.MainContent.ItemImage.Image = ItemData.ImageId
			end
			--glow frame--
			ItemFrame.StrokeGlow.ImageColor3 = RarityIndex[ItemData.Rarity].Color

			--glow brighter on hover
			TweenUtils.GrowOnHover(
				ItemFrame,
				ItemFrame.StrokeGlow.UIScale,
				0.1,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			)
			--events--

			ItemFrame.Button.MouseButton1Click:Connect(function()
				print("Clicked item: " .. ItemData.Name)
				--equip/use item logic goes here--

				--check if they own it. If they do then equip it.
				print(self.ClientDataController.DataCache.Inventory)
				if true then--[[self.ClientDataController.DataCache.Inventory[ItemData.Type][ItemName] then]]
					print("equip")
					--equip item logic
					self.InventoryEvent:Invoke(20, "EquipItem", ItemData.Type, ItemName)
				else
					--make purchase dialogue gui visible
					print("prompt purchase")
					--will most likely need an outer variable such as "SelectedItem" so we only need to create one purchase dialogue
				end
			end)
			ItemFrame.MouseEnter:Connect(function()
				--show tooltip
				ItemTooltipUI.Enabled = true
				--load tooltip content
				--tooltips need to show: name, rarity, special ability, description
				print("item name:" .. ItemData.Name)
			end)

			ItemFrame.MouseLeave:Connect(function()
				--hide tooltip
				ItemTooltipUI.Enabled = false
			end)

			ItemFrame.MouseMoved:Connect(function(x, y)
				--move tooltip
				ItemTooltipUI.Container.Position = UDim2.fromOffset(x,y)
			end)


			
		end
	end
end

return MenuGui

