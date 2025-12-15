--Purpose: Manages status effects to the character, and pretty much anything else that the server may need to handle the character on the server with
--note: very useful when a lot is going on in the game


local CharacterManager = {}


function CharacterManager:ApplyStatusEffect()
    self.StatusEffects = {"Frozen", } 


    --[[

    [PlayerInstance] = {"Frozen", "Burning", ""}
    
    ]]
end


function CharacterManager:CheckStatusEffect(player, StatusName : string)
    
end


function CharacterManager:RemoveStatusEffect(player, StatusName : string, RemoveAll : boolean?)

end

return CharacterManager