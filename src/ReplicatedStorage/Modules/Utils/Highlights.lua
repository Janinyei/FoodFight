local AnimNation = require(script.Parent.AnimNation)
local Highlights = {}

local Cache = {}

local DefaultHighlightColor = Color3.new(1, 0, 0)
function Highlights:GetHighlightForModel(Model)
	if Cache[Model] then
		return Cache[Model]
	end

	local HighlightInstance = Instance.new("Highlight")
	HighlightInstance.FillColor = DefaultHighlightColor
	HighlightInstance.OutlineColor = DefaultHighlightColor
	HighlightInstance.Name = "Highlight"
	HighlightInstance.FillTransparency = 1
	HighlightInstance.OutlineTransparency = 1
	HighlightInstance.DepthMode = Enum.HighlightDepthMode.Occluded
	HighlightInstance.Enabled = true
	HighlightInstance.Parent = Model

	Cache[Model] = HighlightInstance

	local AncestryConnection
	AncestryConnection = HighlightInstance.AncestryChanged:Connect(function()
		if not HighlightInstance.Parent then
			HighlightInstance:Destroy()
			Cache[Model] = nil
			if AncestryConnection then
				AncestryConnection:Disconnect()
				AncestryConnection = nil
			end
		end
	end)
	return HighlightInstance
end

function Highlights:HighlightModel(Model, Color, Duration)
	if not Model or not Model.Parent then
		return
	end

	local HighlightInstance = self:GetHighlightForModel(Model)
	
	HighlightInstance.FillColor = Color or DefaultHighlightColor
	HighlightInstance.OutlineColor = Color or DefaultHighlightColor
	HighlightInstance.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	AnimNation.tween(HighlightInstance, {
		t = 0
	}, {
		FillTransparency = 0.5
	}):Await()
	AnimNation.tween(HighlightInstance, {
		t = Duration or 0.5
	}, {
		FillTransparency = 1
	}):AndThen(function()
		HighlightInstance.DepthMode = Enum.HighlightDepthMode.Occluded
	end)
end

return Highlights

