--purpose: handles spectating controls and spectate menu visiblity
--note: this is really a spectate controller but I didn't really know whether to name it spectateController or spectateGui so I lowk js picked a random one
--note: or maybe call it "SpecateGuiController" 😱
--note: the spectating camera control is primarily handled with the cameracontroller, this module is just focuses on gui control

local SpectateGui = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local RunService = game:GetService("RunService")

local Janitor = require(game.ReplicatedStorage.Modules.Utils.Janitor)

function SpectateGui:Init(Core)
    self.CameraController = Core:Get("CameraController")
    self.InputController = Core:Get("InputController") --for Q/E toggle
    self.MainGui = PlayerGui.Spectate
    self.SpectateEvent = Core:Get("SharedRemotes"):GetEvent("SpectateEvent") --invoke server for spectate list
    self.ScreenGuiController = Core:Get("ScreenGuiController")
  
    self.CurrentPlayer = nil --player you're spectating
    self.CurrentIndex = -1 --for arrow navigation
    self.PlayerList = {}

    self.runtimeJanitor = Janitor.new()
end


function SpectateGui:Start(Core)
    self.SpectateEvent:Connect(function(playerList)
        self.PlayerList = playerList -- updates active player list
    end)

    --setup spectate gui here--
    --click event which opens the menu for you to spectate. Automatically begins at the first index
    --selection is rotating, meaning that reducing the first index will move you to the last. Vice versa
end


function SpectateGui:Cycle(direction: number)
    if #self.PlayerList == 0 then return end
    
    -- direction is 1 (Next) or -1 (Previous)
    self.CurrentIndex = self.CurrentIndex + direction
    
    -- Wrap around logic
    if self.CurrentIndex > #self.PlayerList then
        self.CurrentIndex = 1
    elseif self.CurrentIndex < 1 then
        self.CurrentIndex = #self.PlayerList
    end
    
    self.CameraController:Spectate(self.PlayerList[self.CurrentIndex])
end

function SpectateGui:SpectateRandom()
    if #self.PlayerList > 0 then
        local randIndex = math.random(1, #self.PlayerList)
        self:Spectate(self.PlayerList[randIndex])
    else
        -- Handle "No one left" UI
    end
end

-- Update loop to handle if the person you're spectating leaves or dies
function SpectateGui:Update()
    self.runtimeJanitor:Add(RunService.Heartbeat:Connect(function()
        if self.CurrentPlayer then
            local stillActive = table.find(self.PlayerList, self.CurrentPlayer)
            local hasChar = self.CurrentPlayer.Character ~= nil
            
            if not stillActive or not hasChar then
                self:SpectateRandom()
            end
        end
    end))
end

--fix camera and cleanup run service event
function SpectateGui:Cleanup()
    self.runtimeJanitor:Cleanup() 

end

return SpectateGui