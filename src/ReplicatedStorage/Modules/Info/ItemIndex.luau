--holds all information for level, pricing rarity, etc for the food shop UI
--note: order simply is the layout order for each GUI element

local InventoryIndex = {}

InventoryIndex.Food = {
    ["Burger"] = {
        Name = "Burger",
        Type = "Food",
        Price = 0,
        Rarity = "Common",
        Description = "Just a burger.",
        Order = 1,
        Level = 0,
        ImageId = ""
    },


    ["Tomato"] = {
        Name = "Tomato",
        Type = "Food",
        Price = 500,
        Rarity = "Common",
        Description = "Just a tomato.",
        Order = 2,
        Level = 10,
        ImageId = ""
    },



    ["Chili Pepper"] = {
            Name = "Chili Pepper",
            Type = "Food",  
            Price = 100,
            Rarity = "Rare",
            Description = "Burns enemies over time.",
            Order = 3,
            Level = 30,
            ImageId = ""
        },

}


InventoryIndex.Trails = {

    ["Something"] = {
            Name = "idk",
            Type = "Trails",  
            Price = 100,
            Rarity = "Rare",
            Description = "Burns enemies over time.",
            Order = 3,
            Level = 30,
            Image = ""
        },
}



return InventoryIndex