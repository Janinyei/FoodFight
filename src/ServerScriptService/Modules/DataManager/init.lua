local Players = game:GetService("Players")
local ProfileStore = require(script.ProfileStore)
local DefaultData = require(script.DefaultData)
local module =  {}
local PlayerStore = nil

function module:Init()
    PlayerStore = ProfileStore.New("TestingData",DefaultData)
    self.Profiles = {}
    
end


function module:Start()
  
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = {}

local function PlayerAdded(player)
   -- Start a profile session for this player's data:
   local profile = PlayerStore.Mock:StartSessionAsync(`{player.UserId}`, {
      Cancel = function()
         return player.Parent ~= Players
      end,
   })
   

   -- Handling new profile session or failure to start it:
   if profile ~= nil then

      profile:AddUserId(player.UserId) -- GDPR compliance
      profile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE (optional)

      profile.OnSessionEnd:Connect(function()
         self.Profiles[player] = nil
         player:Kick(`Profile session end - Please rejoin`)
      end)

      if player.Parent == Players then
         self.Profiles[player] = profile
         print(`Profile loaded for {player.DisplayName}!`)
         print(profile)
      else
         -- The player has left before the profile session started
         profile:EndSession()
      end
   else
      -- This condition should only happen when the Roblox server is shutting down
      player:Kick(`Profile load fail - Please rejoin`)
   end

end

-- In case Players have joined the server earlier than this script ran:
for _, player in Players:GetPlayers() do
   task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
   local profile = self.Profiles[player]
   if profile ~= nil then
      profile:EndSession()
   end
end)

end

function module:GetData()
    
end

return module