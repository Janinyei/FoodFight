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

local PlayableModes = {
    "FFA", "TDM"
}

function GameManager:InitModes()
    self.Modes = {
        Intermission = {
            Name = "Intermission",
            Start = function()
                self.Timer:SetTime(INTERMISSION_TIME)
                for _, player in ipairs(Players:GetPlayers()) do
                    self.GameStatusManager:ReturnToLobby(player)
                end
            end,

            OnTick = function(TimeRemaining : number)
                self.TimerEvent:Fires(true, "Intermission:", TimeRemaining)
            end,

            OnComplete = function()
                self:SetRandomGameMode()
            end
        },


       ["FFA"] = {
            Name = "Free for All",
                Start = function()
                    self.Timer:SetTime(120)
                end,
        
                OnTick = function(TimeRemaining : number)
                  self.TimerEvent:Fires(true, self.CurrentMode.Name, TimeRemaining)
                end,
        
                OnComplete = function()
                    for _, player in ipairs(Players:GetPlayers()) do
                        self.GameStatusManager:ReturnToLobby(player)
                    end
                    self:SetMode("Intermission")
            end
       },

       ["TDM"] = {
  Name = "TDM",
                Start = function()
                    self.Timer:SetTime(120)
                end,
        
                OnTick = function(TimeRemaining : number)
                  self.TimerEvent:Fires(true, self.CurrentMode.Name, TimeRemaining)
                end,
        
                OnComplete = function()
                    for _, player in ipairs(Players:GetPlayers()) do
                        self.GameStatusManager:ReturnToLobby(player)
                    end
                    self:SetMode("Intermission")
            end
       },

       ["No Abilities"] = {

       }
    }
end

function GameManager:Init(Core)
    self.Timer = Timer.new(INTERMISSION_TIME)
    self.CurrentMode = nil
    self.TimerEvent = Core:Get("SharedRemotes"):GetEvent("TimerEvent")
    self.GameStatusManager = Core:Get("GameStatusManager")
    self:InitModes()
end

function GameManager:Start()
    --sparks game loop
    self:SetMode("Intermission")

    self.Timer.OnTick:Connect(function(TimeRemaining)
        if self.CurrentMode.OnTick then 
            self.CurrentMode.OnTick(TimeRemaining)
        end
    end)

    self.Timer.OnComplete:Connect(function()
        if self.CurrentMode.OnComplete then 
             self.CurrentMode.OnComplete()
        end     
    end)
end


function GameManager:SetMode(ModeName : string)
    if self.Modes[ModeName] then
    self.CurrentMode = self.Modes[ModeName]
    self.CurrentMode.Start()
    else 
        warn("Round: ".. ModeName.." does not exist" )
    end
end

function GameManager:SetRandomGameMode()
    local SelectedMode = PlayableModes[math.random(1, #PlayableModes)]


    self:SetMode(SelectedMode)
end

function  GameManager:SetMap()
    
end




return GameManager