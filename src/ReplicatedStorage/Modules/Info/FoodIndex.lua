
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
        HitBehavior = "Normal", --normal projectile
        BaseDamage = 5,
        Cooldown = 0.3,
        Price = 0
    },

    Tomato = {
        HitBehavior = "Normal",
        BaseDamage = 5,
        Cooldown = 0.4,
        Price = 250,
    },

    Soda = {
        HitBehavior = "Normal",
        BaseDamage = 5,
        Cooldown = 0.4,
        Price = 250,
    },

    Egg = {
        HitBehavior = "Special"
    },





    Grapes = {

    },

  
    Watermelon = {
        HitBehavior = "Blast", --explosive projectile
        BaseDamage = 15,
        SpecialDamage = 10,
        BlastRadius = 10,
        KnockbackForce = 50,
        KnockbackDuration = 0.5,
    },

}


