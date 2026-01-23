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
local AnimNation = require(ReplicatedStorage.Modules.Utils.AnimNation)

--spring data--
local DefaultSpring = { Speed = 5, Damper = 0.9 }
local FastSpring = { Speed = 8, Damper = 0.6 }

--Gui--

function MenuGui:Init(Core)
	self.ClientDataController = Core:Get("ClientDataController")
	self.ScreenGuiController = Core:Get("ScreenGuiController")
	self.MouseController = Core:Get("MouseController")
	self.CharacterEvent = Core:Get("SharedRemotes"):GetEvent("CharacterEvent")
	self.InventoryEvent = Core:Get("SharedRemotes"):GetEvent("InventoryEvent")
	self.GameController = Core:Get("GameController")

	--GUI--
	self.MenuScreen = PlayerGui.Menu
	self.Timer = PlayerGui.Timer
	self.MenuButtons = self.MenuScreen.MenuButtons

	self.ScreenGuiController.ScreenState.StateChanged:Connect(function(old, new)
		if new == "Menu" then
			self:OnToggle(true, old)
		elseif old == "Menu" then
			self:OnToggle(false, new)
		end
	end)
end

function MenuGui:Start()
	--load menu components and stuff lol

	self:InitMenuButtons()
	self:InitPlayButton()
	self:InitCurrencyGui()
end
--state management--

function MenuGui:OnToggle(Open: boolean, otherState: string)
	local MenuButtons = self.MenuScreen.MenuButtons
	local Progression = self.MenuScreen.Progression
	local Currency = self.MenuScreen.Currency
	local PlayButton = self.MenuScreen.PlayButton
	local TimerFrame = self.Timer.TimerFrame

	if Open then
		self.MenuScreen.Enabled = true

		AnimNation.target(MenuButtons, DefaultSpring, { Position = UDim2.fromScale(0.015, 0.5) })
		AnimNation.target(Progression, DefaultSpring, { Position = UDim2.fromScale(0.5, 0.85) })
		AnimNation.target(Currency, DefaultSpring, { Position = UDim2.fromScale(0.725, 0.95) })

		--timer and play button dynamic
		if self.GameController.GameData.InGame == true then
			AnimNation.target(PlayButton, DefaultSpring, { Position = UDim2.fromScale(0.5, 0.015) })

			AnimNation.target(TimerFrame, DefaultSpring, { Position = UDim2.fromScale(0.5, 0.2) })
		else
			AnimNation.target(PlayButton, DefaultSpring, { Position = UDim2.fromScale(0.5, -0.5) })
			AnimNation.target(TimerFrame, DefaultSpring, { Position = UDim2.fromScale(0.5, 0.1) })
		end
	else
		AnimNation.target(MenuButtons, { Speed = 5, Damper = 0.85 }, { Position = UDim2.fromScale(-0.5, 0.5) })
		AnimNation.target(Progression, DefaultSpring, { Position = UDim2.fromScale(0.5, 1.5) })

		AnimNation.target(PlayButton, FastSpring, { Position = UDim2.fromScale(0.5, -0.5) })
		AnimNation.target(TimerFrame, FastSpring, { Position = UDim2.fromScale(0.5, -0.5) })

		--  hide currency when spawning n shi
		if otherState == "HUD" then
			AnimNation.target(Currency, DefaultSpring, { Position = UDim2.fromScale(0.725, 1.5) })

			--disable screen gui
			task.delay(1, function()
				if self.ScreenGuiController.ScreenState:GetState() ~= "Menu" then
					self.MenuScreen.Enabled = false
				end
			end)
		end
	end
end

--Menu Buttons--
function MenuGui:InitMenuButtons()
	local MenuFrameDefaultColor = Color3.fromRGB(30, 30, 30)
	local MenuPrimaryColors = {
		["Inventory"] = Color3.fromRGB(96, 125, 255),
		["Store"] = Color3.fromRGB(117, 71, 255),
		["Missions"] = Color3.fromRGB(180, 255, 137),
		["Settings"] = Color3.fromRGB(172, 172, 172),
		["Crates"] = Color3.fromRGB(255, 156, 35),
		["Updates"] = Color3.fromRGB(255, 87, 87),
	}

	--replace dark color with color theme on hover

	for _, buttonFrame: GuiObject in self.MenuButtons:GetChildren() do
		if not buttonFrame:IsA("Frame") then
			continue
		end

		local PrimaryColor = MenuPrimaryColors[buttonFrame.Name]

		--set initial colors--

		buttonFrame.ImageLabel.ImageColor3 = PrimaryColor
		buttonFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

		buttonFrame.Button.MouseButton1Click:Connect(function()
			local frameName = buttonFrame.Name
			if PlayerGui:FindFirstChild(frameName) then
				self.ScreenGuiController.ScreenState:SetState(frameName)

				task.delay(3, function()
					self.ScreenGuiController.ScreenState:SetState("Menu")
				end)
			end
		end)

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

	local PlayButton = self.MenuScreen.PlayButton
	local HideY = -0.2
	local DockY = 0.015

	local TimerFrame = PlayerGui.Timer.TimerFrame --need to move timer along with button

	--initial load--

	PlayButton.Position = UDim2.fromScale(0.5, HideY)
	TimerFrame.Position = UDim2.fromScale(0.5, 0.1)

	--set up event to change
	self.GameController.GameDataChanged:Connect(function(data)
		print("data changed play button")

		if not self.ScreenGuiController.ScreenState:IsState("Menu") then return end
		if data.InGame == true then
			AnimNation.target(PlayButton, DefaultSpring, { Position = UDim2.fromScale(0.5, 0.015) })

			AnimNation.target(TimerFrame, DefaultSpring, { Position = UDim2.fromScale(0.5, 0.2) })
		else
			AnimNation.target(PlayButton, DefaultSpring, { Position = UDim2.fromScale(0.5, -0.5) })
			AnimNation.target(TimerFrame, DefaultSpring, { Position = UDim2.fromScale(0.5, 0.1) })
		end
	end)

	TweenUtils.GrowOnHover(
		PlayButton,
		PlayButton.UIScale,
		0.05,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	)

	TweenUtils.ButtonClickTween(PlayButton.Button, PlayButton.UIScale, 0.1, function()
		self.ScreenGuiController.ScreenState:SetState("HUD")

	end)
end

--Progression Gui--
function MenuGui:InitProgressionGui()
	self.ProgressionGui = self.MenuScreen.Progression

	local ProgressionGui = self.ProgressionGui

	local ProgBarContainer = ProgressionGui.Container
	local ProgBar = ProgBarContainer.ProgBar
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
--

--Currency Gui--
function MenuGui:InitCurrencyGui()
	self.CurrencyGui = self.MenuScreen.Currency
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
				self.ScreenGuiController.ScreenState:SetState("Store")
			end)
		end
	end
end

--old stuff--

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
