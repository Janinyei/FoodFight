return {
    --Projectile Data--

    Projectile = {

        Speed = 100,
        InitUpwardVelocity = Vector3.new(0, 10, 0),
        Acceleration = Vector3.new(0, -40, 0),
        MaxBounces = 5,
        MaxHits = 1,
        Restitution = 0.8,
        DestroyOnHit = true,
        IncludeModelInCleanup = false
    },

    Ultimate = {
        DestroyOnHit = true
    },

    Combat = {
        PeelDamage = 5,
        BaseDamage = 20,
        Cooldown = 0.2
    },

    Energy = {
        BoostRate = 100, --how much is increased per second passively
        AbilityCost = 100, --how much is drained every ability activation
        MaxEnergy = 1000 , --maximum energy required for ability activation
    }
}