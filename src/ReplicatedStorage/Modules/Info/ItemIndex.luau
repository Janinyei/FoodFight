local InventoryIndex = {}

InventoryIndex.Food = {
    ["Burger"] = {
        Name = "Burger",
        Type = "Food",
        Price = 0,
        Rarity = "Common",
        Description = "Just a burger.",
        Order = 1
    },

    ["Chili Pepper"] = {
        Name = "Chili Pepper",
        Type = "Food",  
        Price = 100,
        Rarity = "Rare",
        Description = "Burns enemies over time.",
        Order = 2
    },

    ["Tomato"] = {
        Name = "Tomato",
        Type = "Food",
        Price = 500,
        Rarity = "Common",
        Description = "Just a tomato.",
        Order = 3
    }


}

return InventoryIndex