--Purpose: Stores the data schema for new players
--NOTE: Try not to save too much data. Only save the stuff that actually NEEDS to be saved(duh)
--Janin 10/25/25
local module = {
	Coins = 50,
        Gems = 0,
	Level = 0,
	Exp = 0, --Max exp is calculated based on exp & level. No need to save in here.
	Rank = "Novice",
	Inventory = {
		--Food is NOT stack-able
		Food = {
                        Burger = {
                                Name = "Burger",
                                Type = "Food",
                                
                        },
                },

		--Skins ARE stack-able
		Skins = {
			Lava = {
				Name = "Lava",
                                Amount = 1,
                                Type = "Skin"
			},


		},

                
                Auras = {
                        Flame = {
                                Name = "Flame",
                                Amount = 3,
                                Type = "Aura"
                        }
                },

	},

	Settings = {
		Sound = true,
		Music = true,
	},
}

return module
