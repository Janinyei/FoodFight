--Purpose: To Control the flow of the game and the general game loop
--janin 10/28/25

local RoundManager = {}

--Services-
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Utils--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils
local Timer = require(Utils.Timer)

--Constants--
local INTERMISSION_TIME = 15

function RoundManager:Init(Core)
    self.Timer = Timer.new(INTERMISSION_TIME)
    self.CurrentMode = nil
    self.TimerEvent = Core:Get("SharedRemotes"):GetEvent("TimerEvent")
    --list of modes and their functions:

    self.Modes = {
        Intermission = {
            Start = function()
                self.Timer:SetTime(INTERMISSION_TIME)
            end,

            OnTick = function(TimeRemaining : number)
    
                self.TimerEvent:Fires(true, "Intermission:", TimeRemaining)
            end,

            OnComplete = function()
                self:SetMode("InGame")
            end

        },

        InGame = {
            Start = function()
                self.Timer:SetTime(50)
            end,

            OnTick = function(TimeRemaining : number)
              self.TimerEvent:Fires(true, "Intermission:", TimeRemaining)
            end,

            OnComplete = function()
                self:SetMode("Intermission")
            end
        }
    }
end

function RoundManager:Start()
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


function RoundManager:SetMode(ModeName : string)
    if self.Modes[ModeName] then
    self.CurrentMode = self.Modes[ModeName]
    self.CurrentMode.Start()
    else 
        warn("Round: ".. ModeName.." does not exist" )
    end
end




return RoundManager