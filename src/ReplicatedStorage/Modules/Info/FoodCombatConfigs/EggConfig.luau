return {
    --Projectile Data--

    Projectile = {

        Speed = 100,
        InitUpwardVelocity = Vector3.new(0, 10, 0),
        Acceleration = Vector3.new(0, -40, 0),
        MaxBounces = 0,
        Restitution = 1,
        DestroyOnDamage = true
    },

    Combat = {
        ChickenDamage = 20,
        BaseDamage = 20,
    },

    Energy = {
        BoostRate = 100, --how much is increased per second passively
        AbilityCost = 100, --how much is drained every ability activation
        MaxEnergy = 1000 , --maximum energy required for ability activation
    }
}