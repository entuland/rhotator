-- only alter this file if it's named "custom.recipes.lua"
-- alter the recipes as you please and delete / comment out
-- the recipes you don't want to be available in the game
-- the original versions are in "default/recipes.lua"

return {
	["rhotator:screwdriver"] = {
		{"default:copper_ingot"},
		{"group:stick"},
	},
	["rhotator:screwdriver_alt"] = {
		{"default:copper_ingot", "group:stick"},
		{"group:stick", ""},
	},
	["rhotator:cube"] = {
		{"group:wool"},
		{"rhotator:screwdriver"},
	},
}
