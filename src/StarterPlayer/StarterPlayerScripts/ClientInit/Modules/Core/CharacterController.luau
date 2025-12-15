-- Purpose: Controls movement, parkour, character status effects, etc
-- janin 12/12/25

local Players = game:GetService("Players")

local CharacterController = {}

function CharacterController:Init(Core)
    self.Core = Core
    self.SharedRemotes = Core:Get("SharedRemotes")
    self.CharacterEvent = self.SharedRemotes:GetEvent("CharacterEvent")

    -- Current local character & components
    self.Character = nil
    self.Humanoid = nil
    self.HRP = nil

    -- Connections we create so we can clean them up
    self._connections = {}

    -- Status / movement state (expand as needed)
    self.StatusEffects = {} -- e.g. { SpeedBoost = {ExpiresAt = t}, Slowed = {...} }

end


-- Called from StarterCharacterScripts 
function CharacterController:SetupCharacter(char: Model)
    self.Character = char
    self.Humanoid = char:FindFirstChildOfClass("Humanoid")
    self.HRP = char:FindFirstChild("HumanoidRootPart")

    -- Optionally clear old state
    self.StatusEffects = {}

    -- You can hook up per-character logic here (footsteps, custom movement, etc.)
    -- Example:
    -- if self.Humanoid then
    --     table.insert(self._connections, self.Humanoid.Died:Connect(function()
    --         self:OnDied()
    --     end))
    -- end

    -- Fire a local event or remote if you want UIs / other systems to know
    -- self.CharacterEvent:Fire(true, "CharacterReady", char)
end

-- Example stub for status effects
function CharacterController:ApplyStatusEffect(name: string, data: table)
    -- Example:
    -- data = { Duration = 3, SpeedMultiplier = 0.5 }
    self.StatusEffects[name] = {
        Data = data,
        ExpiresAt = tick() + (data.Duration or 0)
    }

    -- You’d then have an update loop someplace (e.g. RunService.Heartbeat in another method)
    -- that checks StatusEffects and applies/removes effects as needed.
end

function CharacterController:UpdateStatusEffects()
    
end



function CharacterController:ClearStatusEffect(name: string)
    self.StatusEffects[name] = nil
end

function CharacterController:GetCharacter()
    return self.Character, self.Humanoid, self.HRP
end

function CharacterController:Destroy()
    -- Clean up connections
    for _, conn in (self._connections) do
        conn:Disconnect()
    end

    self._connections = {}

    -- Clear references
    self.Character = nil
    self.Humanoid = nil
    self.HRP = nil
    self.StatusEffects = {}
end

return CharacterController