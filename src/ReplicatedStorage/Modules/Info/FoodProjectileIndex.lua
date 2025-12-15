
--[[
HitBehavior [Normal, Explosive, Special]: Determines the end behavior of a projectile when it hits any object
DamageBehavior [Normal, Tick] : Determines how a player will be damaged
BaseDamage [number] :  amount of damage that a player will take from a hit from just the projectile
SpecialDamage[number] : amount of damage that a projectile does with it's ability. abilities vary
KnockbackForce[number] : self-explanatory
KnockbackDuration[number] : amount of time force is applied
BlastRadius [number] : reach of the blast hitbox 
]] 

return {
    Burger = {
        BaseDamage = 5,
        Cooldown = 0.3,
    },

    ["Chili Pepper"] = {
        BaseDamage = 4,
        Cooldown = 3,
        SpecialDamage = 2, --burn damage
    },

    Tomato = {
        BaseDamage = 8,
        Cooldown = 0.4,
    },

    Soda = {
        BaseDamage = 5,
        Cooldown = 0.4,
       
    },

    Egg = {
        BaseDamage = 4,
        Cooldown = 0.2,
        SpecialDamage = 3, --chicken damage
        MaxBounces = 4,
    },

    Grapes = {
        BaseDamage = 5,
        Cooldown = 1,
    },

    Banana = {
        BaseDamage = 6,
        Cooldown = 0.5,
    },

    ["Ice Cream"] = {
        BaseDamage = 7,
        Cooldown = 2,
        SpecialDamage = 4, --freeze damage
    },

    Donut = {
        BaseDamage = 5,
        Cooldown = 0.3,
    }
  
   
}


