local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage.Assets
local AnimNation = require(script.Parent.AnimNation)

local DamageNumbers = {}

local BillboardGuis = {}
local ActiveDamageLabels = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function GetBillboardForCharacter(Character)
	if BillboardGuis[Character] then
		return BillboardGuis[Character]
	end

	local Head = Character:FindFirstChild("Head") or Character:FindFirstChild("HumanoidRootPart")
	if not Head then
		return nil
	end

	local Billboard = Instance.new("BillboardGui")
	Billboard.Name = "DamageNumbers_" .. Character.Name
	Billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Billboard.AlwaysOnTop = true
	Billboard.ResetOnSpawn = false
	Billboard.ClipsDescendants = false
	Billboard.Size = UDim2.fromScale(1.75, 1.75)
	Billboard.StudsOffset = Vector3.new(0, 3, 0)
	Billboard.Adornee = Head
	Billboard.Parent = PlayerGui

	BillboardGuis[Character] = Billboard

	Character.Destroying:Connect(function()
		Billboard:Destroy()
		BillboardGuis[Character] = nil
	end)
	return Billboard
end

function DamageNumbers:ShowDamage(Character, Damage, Color)
	if not Character or not Character.Parent then
		return
	end

    print(Character,Damage,Color)

	local Billboard = GetBillboardForCharacter(Character)
	if not Billboard then
		return
	end

	local CurrentTime = os.clock()
	local ActiveLabel = ActiveDamageLabels[Character]

	if ActiveLabel and CurrentTime - ActiveLabel.StartTime < 0.75 then
		ActiveLabel.StartTime = CurrentTime
		local CombinedAmount = ActiveLabel.Amount + Damage
		local MaxDamage = math.min(CombinedAmount, 100)
		ActiveLabel.Amount = math.round(MaxDamage)
		ActiveLabel.Label.Number.Text = tostring(ActiveLabel.Amount)

		AnimNation.target(ActiveLabel.Label.Number, {
			s = 30,
			d = 1
		}, {
			TextColor3 = Color or Color3.new(1, 1, 1)
		})
	else
		local Label = Assets.UI.DamageNumber:Clone()
		Label.Parent = Billboard
		ActiveLabel = {
			StartTime = CurrentTime,
			Amount = Damage,
			Label = Label
		}
		ActiveDamageLabels[Character] = ActiveLabel

		task.spawn(function()
			local StartTime = os.clock()
			while ActiveLabel and os.clock() - StartTime < 0.75 do
				local Alpha = (os.clock() - StartTime) / 0.75
				if ActiveLabel.Label and ActiveLabel.Label.Parent then
					ActiveLabel.Label.Number.TextTransparency = Alpha
					if ActiveLabel.Label.Number:FindFirstChild("UIStroke") then
						ActiveLabel.Label.Number.UIStroke.Transparency = Alpha
					end
				end
				task.wait()
			end

			if ActiveLabel and ActiveLabel.Label then
				ActiveLabel.Label:Destroy()
			end
			if ActiveDamageLabels[Character] == ActiveLabel then
				ActiveDamageLabels[Character] = nil
			end
		end)
	end
	if ActiveLabel and ActiveLabel.Label then
		AnimNation.impulse(ActiveLabel.Label.Number, {
			s = 30,
			d = 0.6
		}, {
			Size = UDim2.fromScale(1, 1.5)
		})
	end
end

return DamageNumbers
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage.Assets
local AnimNation = require(script.Parent.AnimNation)

local DamageNumbers = {}

local BillboardGuis = {}
local ActiveDamageLabels = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function GetBillboardForCharacter(Character)
	if BillboardGuis[Character] then
		return BillboardGuis[Character]
	end

	local Head = Character:FindFirstChild("Head") or Character:FindFirstChild("HumanoidRootPart")
	if not Head then
		return nil
	end

	local Billboard = Instance.new("BillboardGui")
	Billboard.Name = "DamageNumbers_" .. Character.Name
	Billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Billboard.AlwaysOnTop = true
	Billboard.ResetOnSpawn = false
	Billboard.ClipsDescendants = false
	Billboard.Size = UDim2.fromScale(1.75, 1.75)
	Billboard.StudsOffset = Vector3.new(0, 3, 0)
	Billboard.Adornee = Head
	Billboard.Parent = PlayerGui

	BillboardGuis[Character] = Billboard

	Character.Destroying:Connect(function()
		Billboard:Destroy()
		BillboardGuis[Character] = nil
	end)
	return Billboard
end

function DamageNumbers:ShowDamage(Character, Damage, Color)
	if not Character or not Character.Parent then
		return
	end

	local Billboard = GetBillboardForCharacter(Character)
	if not Billboard then
		return
	end

	local CurrentTime = os.clock()
	local ActiveLabel = ActiveDamageLabels[Character]

	if ActiveLabel and CurrentTime - ActiveLabel.StartTime < 0.75 then
		ActiveLabel.StartTime = CurrentTime
		local CombinedAmount = ActiveLabel.Amount + Damage
		local MaxDamage = math.min(CombinedAmount, 100)
		ActiveLabel.Amount = math.round(MaxDamage)
		ActiveLabel.Label.Number.Text = tostring(ActiveLabel.Amount)

		AnimNation.target(ActiveLabel.Label.Number, {
			s = 30,
			d = 1
		}, {
			TextColor3 = Color or Color3.new(1, 1, 1)
		})
	else
		local Label = Assets.UI.DamageNumber:Clone()
		Label.Parent = Billboard
		ActiveLabel = {
			StartTime = CurrentTime,
			Amount = Damage,
			Label = Label
		}
		ActiveDamageLabels[Character] = ActiveLabel

		task.spawn(function()
			local StartTime = os.clock()
			while ActiveLabel and os.clock() - StartTime < 0.75 do
				local Alpha = (os.clock() - StartTime) / 0.75
				if ActiveLabel.Label and ActiveLabel.Label.Parent then
					ActiveLabel.Label.Number.TextTransparency = Alpha
					if ActiveLabel.Label.Number:FindFirstChild("UIStroke") then
						ActiveLabel.Label.Number.UIStroke.Transparency = Alpha
					end
				end
				task.wait()
			end

			if ActiveLabel and ActiveLabel.Label then
				ActiveLabel.Label:Destroy()
			end
			if ActiveDamageLabels[Character] == ActiveLabel then
				ActiveDamageLabels[Character] = nil
			end
		end)
	end
	if ActiveLabel and ActiveLabel.Label then
		AnimNation.impulse(ActiveLabel.Label.Number, {
			s = 30,
			d = 0.6
		}, {
			Size = UDim2.fromScale(1, 1.5)
		})
	end
end

return DamageNumbers