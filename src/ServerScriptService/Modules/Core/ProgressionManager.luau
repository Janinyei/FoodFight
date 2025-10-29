--Purpose: levels and rank management.
--janin 10/28/25

local ProgressionManager = {}


--Services--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Variables--
local Modules = ReplicatedStorage.Modules
local Utils = Modules.Utils
local Ranks = require(Modules.Info.RankIndex)

--Constants--
local LEVEL_CAP = 100

function ProgressionManager:Init(Core)
    self.DataManager = Core:Get("DataManager")
    self.ProgressionEvent = Core:Get("SharedRemotes"):GetEvent("ProgressionEvent")

end

function ProgressionManager:Start()

    --test--
  self.DataManager.DataLoaded:Connect(function(Player, Data)
    
        ProgressionManager:IncreaseExp(Player, Data, 50000)
    end)
end

--functions

function ProgressionManager:IncreaseExp(Player : Player, Data, Amount : number)
    local Data = Data
    local ProgressionData = Data.Progression

    local Exp = ProgressionData.Exp
    local Level = ProgressionData.Level

    local MaxExp = self:CalculateMaxExp(Level)

    ProgressionData.Exp += Amount

    print(MaxExp)
  if Exp >= MaxExp then
    print("lvl up")
    repeat 
        --Level up logic
        ProgressionData.Level = math.clamp(ProgressionData.Level + 1, 0, LEVEL_CAP)
        ProgressionData.Exp  -= MaxExp
        MaxExp = self:CalculateMaxExp(Level)

        --determines whether players increase their rank or not
        local RankUp = self:CheckRank(ProgressionData.Level, ProgressionData.Rank)
        if RankUp then 
            print("Rank up!")
            ProgressionData.Rank = RankUp
        end

  
        self.ProgressionEvent:Fire(true, Player,ProgressionData, MaxExp) --sends to client cache. sent MaxExp since it's not being saved

    until ProgressionData.Exp < ProgressionData.MaxExp
    print("done incrementing")
  else
    self.ProgressionEvent:Fire(true, Player ,ProgressionData, MaxExp)
  end
end

--calculates maximum experience required to level up based on current level
function ProgressionManager:CalculateMaxExp(Level : number)
    return math.ceil((Level/2) * math.log10((Level+1)^2) * 100 + 100) --some formula I came up with
end

function ProgressionManager:CheckRank(Level :number, CurrentRank : string)
    
    for RankName, RequiredLevel in Ranks do
        if Level >= RequiredLevel and CurrentRank ~= RankName then
            return RankName
        end
    end

    return false
end





return ProgressionManager