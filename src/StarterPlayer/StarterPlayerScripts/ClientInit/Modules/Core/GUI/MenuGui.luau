--Purpose: controls the main menu screen and its components
--Note: ngl this is probably gonna be a long script so apologies in advance
--janin 11/2/25

local MenuGui = {}
--Services--
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
	self.GameController = Core:Get("GameController")

	--loads menu components--

	self:InitMenuButtons()
	self:InitPlayButton()
	self:InitProgressionGui()
	--	self:InitCurrencyGui()
	--	self:InitBottomFrame()
	--	self:InitInventoryGui()
end

function MenuGui:Start() end

--Menu Buttons--
function MenuGui:InitMenuButtons()
	local MenuButtons = self.MenuScreen.MenuButtons
	local MenuFrameDefaultColor = Color3.fromRGB(30, 30, 30)
	local MenuPrimaryColors = {
		["Inventory"] = Color3.fromRGB(96, 125, 255),
		["Shop"] = Color3.fromRGB(117, 71, 255),
		["Missions"] = Color3.fromRGB(180, 255, 137),
		["Settings"] = Color3.fromRGB(172, 172, 172),
		["Crates"] = Color3.fromRGB(255, 156, 35),
		["Updates"] = Color3.fromRGB(255, 87, 87),
	}

	--replace dark color with color theme on hover

	for _, buttonFrame: GuiObject in MenuButtons:GetChildren() do
		if not buttonFrame:IsA("Frame") then
			continue
		end

		local PrimaryColor = MenuPrimaryColors[buttonFrame.Name]

		--set initial colors--

		buttonFrame.ImageLabel.ImageColor3 = PrimaryColor
		buttonFrame.BackgroundColor3 = PrimaryColor

		buttonFrame.MouseEnter:Connect(function()

			if PrimaryColor then
				TweenService:Create(
					buttonFrame,
					TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ BackgroundColor3 = PrimaryColor }
				):Play()
				TweenService:Create(
					buttonFrame.ImageLabel,
					TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ ImageColor3 = Color3.fromRGB(255, 255, 255) }
				):Play()

				--insert audio--
			end
		end)

		buttonFrame.MouseLeave:Connect(function()

			--	buttonFrame.BackgroundColor3 = MenuFrameDefaultColor

			TweenService:Create(
				buttonFrame,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ BackgroundColor3 = MenuFrameDefaultColor }
			):Play()
			TweenService:Create(
				buttonFrame.ImageLabel,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ ImageColor3 = PrimaryColor }
			):Play()
		end)
	end
end

function MenuGui:InitPlayButton()
	--load as flat or whatever
	--the menu timer will be modified in the timergui script isntead of here
	local TopArea = self.MenuScreen.TopArea
	local Top = TopArea.Top
	local PlayButton = Top.PlayButton

	local InitHeight = Top.Size.Y.Scale

	Top.Size = UDim2.fromScale(Top.Size.X.Scale, 0) --flatten

	--set up event to change
	self.GameController.GameDataChanged:Connect(function(data)
		if data.InGame == true then
			TweenService:Create(
				Top,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ Size = UDim2.fromScale(Top.Size.X.Scale, InitHeight) }
			):Play()
		else
			TweenService:Create(
				Top,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ Size = UDim2.fromScale(Top.Size.X.Scale, 0) }
			):Play()
		end
	end)

	TweenUtils.GrowOnHover(
		PlayButton,
		PlayButton.UIScale,
		0.1,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	)

	TweenUtils.ButtonClickTween(PlayButton, PlayButton.UIScale, 0.1, function()
		self.CharacterEvent:Invoke(8, "Spawn")
	end)
end

function MenuGui:OnClose()
	
end


--Progression Gui--
function MenuGui:InitProgressionGui()
	self.ProgressionGui = self.MenuScreen.Progression

	local ProgressionGui = self.ProgressionGui

	local ProgBarContainer = ProgressionGui.Container
	local ProgBar = Container.ProgBar
	local PlayerName = self.ProgressionGui.PlayerName

	self.ClientDataController.ProgressionChanged:Connect(function(ProgressionData)
		local MaxExp = math.ceil((ProgressionData.Level / 2) * math.log10((ProgressionData.Level + 1) ^ 2) * 100 + 100) --just copied the formula
		--level text
		ProgressionGui.Progression.LevelNum.Text = tostring(ProgressionData.Level)


		--exp bar text and sizing
		ProgBarContainer.ExpAmount.Text = tostring(ProgressionData.Exp) .. " | " .. tostring(MaxExp)

		local ProgressPercent = ProgressionData.Exp / MaxExp
		-- ProgressBar.Size = UDim2.fromScale(ProgressPercent, 1)
		TweenUtils.TweenBar(ProgBarContainer, ProgressPercent, 0.5)

		--update stats

		local Stats = ProgressionData.Stats

		for statName, statValue in Stats do 
			
		end
	end)
end



--old code below--

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
					Button.UIStroke.Color = Color3.fromRGB(255, 255, 255)

					--change other buttons back
					for _, OtherButton in TabContainer:GetChildren() do
						if OtherButton:IsA("Frame") and OtherButton ~= Button then
							OtherButton.UIStroke.Color = Color3.fromRGB(50, 50, 50)
						end
					end
				end
			end)
		end
	end

	--load items in inventory pages--
	local InventoryItemTemplate = InventoryGui.PageContainer.Food.ItemFrame --item template for all of the inventory
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
				ItemTooltipUI.Container.Position = UDim2.fromOffset(x, y)
			end)
		end
	end
end

return MenuGui
