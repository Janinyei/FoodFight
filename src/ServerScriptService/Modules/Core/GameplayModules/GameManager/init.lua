--Purpose: To Control the flow of the game and the general game loop, game modes
--janin 10/28/25

local GameManager = {}

--Services-
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--Utils--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils
local Timer = require(Utils.Timer)

--Constants--
local INTERMISSION_TIME = 3

function GameManager:GetSpawnPoint()
	local Spawns = workspace.Map.Spawns
	if Spawns then
		local children = Spawns:GetChildren()
		if #children > 0 then
			return children[math.random(1, #children)].CFrame
		end
	end
end



function GameManager:InitModes(Core)
	local ModeFolder = script.Modes

	for _, module in ModeFolder:GetChildren() do
		local modeModule = require(module)

		self.ModesTable[module.Name] = modeModule

		if modeModule.InitMode then
			modeModule:InitMode(Core)
		end
	end
end

function GameManager:Init(Core)
	self.Timer = Timer.new(INTERMISSION_TIME)
	self.CurrentMode = nil
	self.TimerEvent = Core:Get("SharedRemotes"):GetEvent("TimerEvent")
	self.GameStatusManager = Core:Get("GameStatusManager")
	self.MatchStatsManager = Core:Get("MatchStatsManager")

	--mode table--
	self.ModesTable = {} --table of loaded modules
	self:InitModes(Core)

	print(self.ModesTable)

	--playable modes (modes you can vote for and have countdowns with). Idk how to fully explain but js know they excluded from Intermission, Countdown, and Voting modes

	local PlayableModes = {
		"FFA",
		"TDM",
		"KOH",
		"CTF"
	}

	self.PlayableModes = PlayableModes
end

function GameManager:Start()
	--sparks game loop by setting to intermission
	self:SetMode("Intermission")

	self.Timer.OnTick:Connect(function(TimeRemaining)
		self.TimerEvent:Fires(true, self.CurrentMode.DisplayName or self.CurrentMode.Name, TimeRemaining)

		if self.CurrentMode.OnTick then
			self.CurrentMode:OnTick(TimeRemaining)
		end
	end)

	self.Timer.OnComplete:Connect(function()

        
        if table.find(self.PlayableModes, self.CurrentMode.Name) ~= nil then
            --automatically set to intermission for playable game modes so you don't have to repeat it constantly
            self:SetMode("Intermission")
        end

		if self.CurrentMode.OnComplete then
			self.CurrentMode:OnComplete()
		end

	end)
end

--sets mode and automatically starts it
function GameManager:SetMode(ModeName: string)
	if self.ModesTable[ModeName] then
		self.CurrentMode = self.ModesTable[ModeName]
		self.CurrentMode:StartMode()

		print("set mode to " .. ModeName)

		--start timer
		local duration = self.CurrentMode.Duration or 20
		self.Timer:SetTime(duration)
	else
		warn("Round: " .. ModeName .. " does not exist")
	end
end

function GameManager:SetRandomGameMode()
	local SelectedMode = self.PlayableModes[math.random(1, #self.PlayableModes)]

	self:SetMode(SelectedMode)
end

function GameManager:SetMap() end

return GameManager
