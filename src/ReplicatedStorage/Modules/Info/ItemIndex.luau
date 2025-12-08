--holds all information for level, pricing rarity, etc for the food shop UI
--note: order simply is the layout order for each GUI element

local InventoryIndex = {}

InventoryIndex.Food = {
	["Burger"] = {
		Name = "Burger",
		Type = "Food",
		Price = 0,
		Rarity = "Common",
		Description = "food description",
		Order = 0,
		Level = 0,
		ImageId = "rbxassetid://71280084030598",
	},

	["Steak"] = {
		Name = "Steak",
		Type = "Food",
		Price = 0,
		Rarity = "Common",
		Description = "food description",
		Order = 1,
		Level = 0,
		ImageId = "rbxassetid://116246770655463",
	},

	["Egg"] = {
		Name = "Egg",
		Type = "Food",
		Price = 0,
		Rarity = "Common",
		Description = "food description",
		Order = 2,
		Level = 0,
		ImageId = "rbxassetid://83180358429095",
	},

	["Banana"] = {
		Name = "Banana",
		Type = "Food",
		Price = 0,
		Rarity = "Common",
		Description = "food description",
		Order = 3,
		Level = 0,
		ImageId = "rbxassetid://133025883164326",
	},

	["Tomato"] = {
		Name = "Tomato",
		Type = "Food",
		Price = 500,
		Rarity = "Uncommon",
		Description = "food description",
		Order = 4,
		Level = 10,
		ImageId = "rbxassetid://128380699644658",
	},

	["Grapes"] = {
		Name = "Burger",
		Type = "Food",
		Price = 0,
		Rarity = "Rare",
		Description = "food description",
		Order = 5,
		Level = 0,
		ImageId = "rbxassetid://124755751749444",
	},

	["Ice Cream"] = {
		Name = "Ice Cream",
		Type = "Food",
		Price = 0,
		Rarity = "Epic",
		Description = "food description",
		Order = 6,
		Level = 0,
		ImageId = "rbxassetid://120842810473114",
	},

	["Donut"] = {
		Name = "Donut",
		Type = "Food",
		Price = 0,
		Rarity = "Rare",
		Description = "food description",
		Order = 7,
		Level = 0,
		ImageId = "rbxassetid://73012614078554",
	},

	["Chili Pepper"] = {
		Name = "Chili Pepper",
		Type = "Food",
		Price = 100,
		Rarity = "Legendary",
		Description = "Burns enemies over time.",
		Order = 8,
		Level = 30,
		ImageId = "rbxassetid://94328709503951",
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
		Image = "",
	},
}

return InventoryIndex
