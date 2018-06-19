rhotator = {}

rhotator.mod_path = minetest.get_modpath(minetest.get_current_modname())

local matrix = dofile(rhotator.mod_path .. "/lib/matrix.lua")

local enable_chat_notifications = false

-- constants

local POS = {}
local NEG = {}
POS.Y = 0
POS.Z = 1
NEG.Z = 2
POS.X = 3
NEG.X = 4
NEG.Y = 5

PRIMARY_BTN = 1
SECONDARY_BTN = 2

-- helper tables

local rot_matrices = {}
local dir_matrices = {}

-- init

local function init_transforms()
	local rot = {}
	local dir = {}

	-- no rotation
	rot[0] = matrix{{  1,  0,  0},
	                {  0,  1,  0},
	                {  0,  0,  1}}
	-- 90 degrees clockwise
	rot[1] = matrix{{  0,  0,  1},
	                {  0,  1,  0},
	                { -1,  0,  0}}
	-- 180 degrees
	rot[2] = matrix{{ -1,  0,  0},
	                {  0,  1,  0},
	                {  0,  0, -1}}
	-- 270 degrees clockwise
	rot[3] = matrix{{  0,  0, -1},
	                {  0,  1,  0},
	                {  1,  0,  0}}

	rot_matrices = rot

	-- directions
	-- Y+
	dir[0] = matrix{{  1,  0,  0},
	                {  0,  1,  0},
	                {  0,  0,  1}}
	-- Z+
	dir[1] = matrix{{  1,  0,  0},
	                {  0,  0, -1},
	                {  0,  1,  0}}
	-- Z-
	dir[2] = matrix{{  1,  0,  0},
	                {  0,  0,  1},
	                {  0, -1,  0}}
	-- X+
	dir[3] = matrix{{  0,  1,  0},
	                { -1,  0,  0},
	                {  0,  0,  1}}
	-- X-
	dir[4] = matrix{{  0, -1,  0},
	                {  1,  0,  0},
	                {  0,  0,  1}}
	-- Y-
	dir[5] = matrix{{ -1,  0,  0},
	                {  0, -1,  0},
	                {  0,  0,  1}}

	dir_matrices = dir

	rhotator._facedir_transform = {}
	rhotator._matrix_to_facedir = {}

	for facedir = 0, 23 do
		local direction = math.floor(facedir / 4)
		local rotation = facedir % 4
		local transform = dir[direction] * rot[rotation]
		rhotator._facedir_transform[facedir] = transform
		rhotator._matrix_to_facedir[transform:tostring():gsub("%-0", "0")] = facedir
	end

end

init_transforms()

-- helper functions

local function cross_product(a, b)
	return vector.new(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
	)
end

local function extract_main_axis(dir)
	local axes = { "x", "y", "z" }
	local axis = 1
	local max = 0
	for i = 1, 3 do
		local abs = math.abs(dir[axes[i]])
		if abs > max then
			axis = i
			max = abs
		end
	end
	return axes[axis]
end

local function sign(num)
	return (num < 0) and -1 or 1
end

local function extract_unit_vectors(player, pointed_thing)
	assert(pointed_thing.type == "node")
	local abs_face_pos = minetest.pointed_thing_to_face_pos(player, pointed_thing)
	local pos = pointed_thing.under
	local f = vector.subtract(abs_face_pos, pos)
	local facedir = 0
	local primary = 0

	local m1, m2

	local unit_direction = vector.new()
	local unit_rotation = vector.new()
	local rotation = vector.new()

	if math.abs(f.y) == 0.5 then
		unit_direction.y = sign(f.y)
		rotation.x = f.x
		rotation.z = f.z
	elseif math.abs(f.z) == 0.5 then
		unit_direction.z = sign(f.z)
		rotation.x = f.x
		rotation.y = f.y
	else
		unit_direction.x = sign(f.x)
		rotation.y = f.y
		rotation.z = f.z
	end

	local main_axis = extract_main_axis(rotation)

	unit_rotation[main_axis] = sign(rotation[main_axis])

	return {
		back = unit_direction,
		wrap = unit_rotation,
		thumb = cross_product(unit_direction, unit_rotation),
	}
end

local function get_facedir_transform(facedir)
	return rhotator._facedir_transform[facedir] or rhotator._facedir_transform[0]
end

local function matrix_to_facedir(mtx)
	local key = mtx:tostring():gsub("%-0", "0")
	if not rhotator._matrix_to_facedir[key] then
		error("Unsupported matrix:\n" .. key)
	end
	return rhotator._matrix_to_facedir[key]
end

local function notify(playername, message)
	if enable_chat_notifications then
		minetest.chat_send_player(playername, "[rhotator] " .. message)
	end
end

local function vector_to_dir_index(vec)
	local main_axis = extract_main_axis(vec)
	if main_axis == "x" then return (vec.x > 0) and POS.X or NEG.X end
	if main_axis == "z" then return (vec.z > 0) and POS.Z or NEG.Z end
	return (vec.y > 0) and POS.Y or NEG.Y
end

-- rhotator main

local function interact(itemstack, player, pointed_thing, click)
	if pointed_thing.type ~= "node" then
		return
	end

	local node = minetest.get_node_or_nil(pointed_thing.under)
	local def = minetest.registered_nodes[node.name]

	if not node or not def then
		notify(player:get_player_name(), "Unsupported node type: " .. node.name)
		return
	end

	if def.paramtype2 ~= "facedir" then
		notify(player:get_player_name(), "Cannot rotate node with paramtype2 == " .. def.paramtype2)
		return
	end

	local unit = extract_unit_vectors(player, pointed_thing)

	local transform = false

	if click == PRIMARY_BTN then
		transform = dir_matrices[vector_to_dir_index(unit.thumb)]
		notify(player:get_player_name(), "Pushed closest edge (left click)")
	else
		transform = dir_matrices[vector_to_dir_index(unit.back)]
		notify(player:get_player_name(), "Rotated pointed face (right click)")
	end

	local start = get_facedir_transform(node.param2)
	local stop = transform * rot_matrices[1] * transform:invert() * start

	minetest.set_node(pointed_thing.under,{
		name = node.name,
		param1 = node.param1,
		param2 = matrix_to_facedir(stop),
	})

end

minetest.register_tool("rhotator:screwdriver", {
	description = "Rhotator Screwdriver (left-click pushes edge, right-click rotates face)",
	inventory_image = "rhotator.png",
	on_use = function(itemstack, player, pointed_thing)
		interact(itemstack, player, pointed_thing, PRIMARY_BTN)
		return itemstack
	end,
	on_place = function(itemstack, player, pointed_thing)
		interact(itemstack, player, pointed_thing, SECONDARY_BTN)
		return itemstack
	end,
})

minetest.register_craft({
	output = "rhotator:screwdriver",
	recipe = {
		{"default:copper_ingot"},
		{"group:stick"}
	}
})

minetest.register_node("rhotator:cube", {
	drawtype = "mesh",
	mesh = "rhotocube.obj",
	tiles = { "rhotocube.png" },
	paramtype2 = "facedir",
	description = "Rhotator Testing Cube",
	walkable = true,
	groups = { snappy = 2, choppy = 2, oddly_breakable_by_hand = 3 },
})

minetest.register_craft({
	output = "rhotator:cube",
	recipe = {
		{"group:wool"},
		{"rhotator:screwdriver"},
	}
})
