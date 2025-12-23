return {
    --Projectile Data--

    Projectile = {
        Speed = 100,
        InitUpwardVelocity = Vector3.new(0, 5, 0),
        Acceleration = Vector3.new(0, -40, 0),
        MaxBounces = 2,
        MaxHits = 1,
        Restitution = 0.7,
        DestroyOnHit = true,
        BurstCount = 5,
        Spread = 0.08,
    },

    Ultimate = {
        DestroyOnHit = true,
        GatlingCount = 30,
        FireRate = 0.05,
        Spread = 0.04,
    },

    Combat = {
        BaseDamage = 8,
        UltimateDamage = 6,
        Cooldown = 0.6
    },

    Energy = {
        BoostRate = 100, --how much is increased per second passively
        AbilityCost = 100, --how much is drained every ability activation
        MaxEnergy = 1000 , --maximum energy required for ability activation
    }
}
