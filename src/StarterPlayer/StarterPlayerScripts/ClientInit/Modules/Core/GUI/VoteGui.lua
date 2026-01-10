local VoteGui = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui



function VoteGui:Init(Core)
	self.SharedRemotes = Core:Get("SharedRemotes")
	self.MouseController = Core:Get("MouseController") --for mouse unlock when using gui

	self.VoteGui = PlayerGui.Voting
	self.VoteEvent = self.SharedRemotes:GetEvent("VoteEvent")

	self.isVoting = false

	self.VoteData = {
		--numbers, not names
		SelectedMap = nil, 
		SelectedMode = nil,
	}
end

function VoteGui:Start()
	self.VoteEvent:Connect(function(action, optionData)
		if action == "Enable" then
			--make vote gui visible
			self.VoteGui.Enabled = true
			self.isVoting = true

			self:_loadVoteGui(optionData)
			
		elseif action == "Disable" then
			self.VoteGui.Enabled = false
			self.isVoting = false
		end
	end)



    local MapSection = self.VoteGui.Container.Maps
    local ModeSection = self.VoteGui.Container.Modes

    --on click events to trigger votes

	for _, votingSection in self.VoteGui.Container:GetChildren() do
		if votingSection:IsA("Frame") then
			for _, optionFrame in  votingSection:GetChildren() do
				if optionFrame:IsA("Frame") then
					local voteType = votingSection.Name
					local voteIndex = optionFrame.Name --options are simply numbers

					optionFrame.ImageButton.MouseButton1Click:Connect(function()
						print(voteIndex)
						self.VoteEvent:Fire(true, {
							voteType = voteType,
							voteIndex = voteIndex
						})
					end)
				end
			end
		end
	end	
end


--priv--

--loads images and names of gui
function VoteGui:_loadVoteGui(optionData)
	for voteType, optionList in optionData do
		print(voteType)
		print(optionList)

		for index, optionName in optionList do
			local targetOptionFrame = self.VoteGui.Container[voteType][index]
			targetOptionFrame.TextLabel.Text = optionName
			--targetOptionFrame.ImageButton.Image = "" --use config to find this
		end
	end
end



return VoteGui
