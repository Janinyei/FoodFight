

--mode purpose:

--[[
clean up current map(if exists)
clean up any kind of hitboxes, projects, etc
disable combat 
]]

--janin 1/10/26

local Voting = {}


function Voting:InitMode(Core)
    self.FoodCombatController = Core:Get("FoodCombatManager")
    self.GameStatusController = Core:Get("GameStatusManager")
    self.GameManager = Core:Get("GameManager")
    self.VoteManager = Core:Get("VoteManager")
    self.TeamManager = Core:Get("TeamManager")
    self.MapManager = Core:Get("MapManager")
  

    self.Name = "Voting"
    self.Duration = 5 --typical duration
    
end

function Voting:StartMode()
   
    print("starting voting")

    self.VoteManager:EnableVoting()
end


function Voting:OnComplete()
    print("complete voting")
    --clean up leaderboard stats, use team manager to create balanced teams

    self.VoteManager:DisableVoting() --disables votes


    self.TeamManager:CleanupTeams() --clears team table

   -- self.VoteManager:SetupTeams()--creates teams from votes

   self.TeamManager:CreateTeam("red")
   self.TeamManager:CreateTeam("blue")

   self.TeamManager:AutoAssignBalancedTeams()


   
   print(self.TeamManager.Teams)

   
   local Map, Mode =   self.VoteManager:GetWinners()
   self.MapManager:LoadMap(Map)
   
   --enable spawning using charactermanager
   

   task.wait(5) --map load delay

   --
    self.GameManager:SetMode(Mode)
end




return Voting