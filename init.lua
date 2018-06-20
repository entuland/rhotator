rhotator = {}

local mod_path = minetest.get_modpath(minetest.get_current_modname())

local matrix = dofile(mod_path .. "/lib/matrix.lua")

-- constants

local POS = {}
local NEG = {}
POS.Y = 0
POS.Z = 1
NEG.Z = 2
POS.X = 3
NEG.X = 4
NEG.Y = 5

local PRIMARY_BTN = 1
local SECONDARY_BTN = 2

rhotator.PRIMARY_BTN = PRIMARY_BTN
rhotator.SECONDARY_BTN = SECONDARY_BTN

-- ============================================================
-- helper variables

local rot_matrices = {}
local dir_matrices = {}

local huds = {}
local hud_timeout_seconds = 3

-- ============================================================
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

-- ============================================================
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

local function vector_to_dir_index(vec)
	local main_axis = extract_main_axis(vec)
	if main_axis == "x" then return (vec.x > 0) and POS.X or NEG.X end
	if main_axis == "z" then return (vec.z > 0) and POS.Z or NEG.Z end
	return (vec.y > 0) and POS.Y or NEG.Y
end

-- ============================================================
-- hud functions

local function hud_remove(player)
	local playername = player:get_player_name()
	local hud = huds[playername]
	if not hud then return end
	if os.time() < hud_timeout_seconds + hud.time then
		return
	end
	player:hud_remove(hud.id)
	huds[playername] = nil
end

local function hud_create(player, message)
	local playername = player:get_player_name()
	local id = player:hud_add({
		text = message,
		hud_elem_type = "text",
		name = "rhotator_feedback",
		direction = 0,
		position = { x = 0.1, y = 0.9},
		alignment = { x = 1, y = -1},
		number = 0xFFFFFF,
	})
	huds[playername] = {
		id = id,
		time = os.time(),
	}
end

local function notify(player, message)
	message = "[rhotator] " .. message
	local playername = player:get_player_name()
	local hud = huds[playername]
	if not hud then
		hud_create(player, message)
	else
		player:hud_change(hud.id, "text", message)
		hud.time = os.time()
	end
	minetest.after(hud_timeout_seconds, function()
		hud_remove(player)
	end)
end

-- ============================================================
-- rhotator main

local function rotate_main(param2_rotation, player, pointed_thing, click, rot_index)
	local unit = extract_unit_vectors(player, pointed_thing)
	local current_pos = pointed_thing.under
	
	local message
	local transform = false
	local rotation = rot_matrices[rot_index]
	
	local controls = player:get_player_control()
	
	if click == PRIMARY_BTN then
		transform = dir_matrices[vector_to_dir_index(unit.thumb)]
		if controls.sneak then
			rotation = rot_matrices[(rot_index + 2) % 4]
			message = "Pulled closest edge (sneak + left click)"
		else
			message = "Pushed closest edge (left click)"
		end
	else
		transform = dir_matrices[vector_to_dir_index(unit.back)]
		if controls.sneak then
			rotation = rot_matrices[(rot_index + 2) % 4]
			message = "Rotated pointed face counter-clockwise (sneak + right click)"
		else
			message = "Rotated pointed face clockwise (right click)"	
		end
	end

	local start = get_facedir_transform(param2_rotation)
	local stop = transform * rotation * transform:invert() * start
	return matrix_to_facedir(stop), message
	
end

-- ============================================================
-- param2 handlers

local handlers = {}

function handlers.facedir(node, player, pointed_thing, click)	
	local rotation = node.param2 % 32 -- get first 5 bits
	local remaining = node.param2 - rotation
	local rotate_90deg_clockwise = 1
	local rotation_result, message = rotate_main(rotation, player, pointed_thing, click, rotate_90deg_clockwise)
	return rotation_result + remaining, message
end

handlers.colorfacedir = handlers.facedir

-- ============================================================
-- Replicate default screwdriver behavior for wallmounted nodes

-- For attached wallmounted nodes: returns true if rotation is valid
-- simplified version of minetest:builtin/game/falling.lua#L148.
local function check_attached_node(pos, rotation)
	local d = minetest.wallmounted_to_dir(rotation)
	local p2 = vector.add(pos, d)
	local n = minetest.get_node(p2).name
	local def2 = minetest.registered_nodes[n]
	if def2 and not def2.walkable then
		return false
	end
	return true
end

local wallmounted_tbl = {
	[PRIMARY_BTN] = {[2] = 5, [3] = 4, [4] = 2, [5] = 3, [1] = 0, [0] = 1},
	[SECONDARY_BTN] = {[2] = 5, [3] = 4, [4] = 2, [5] = 1, [1] = 0, [0] = 3}
}

function handlers.wallmounted(node, player, pointed_thing, click)
	local pos = pointed_thing.under
	local rotation = node.param2 % 8 -- get first 3 bits
	local other = node.param2 - rotation
	rotation = wallmounted_tbl[click][rotation] or 0
	if minetest.get_item_group(node.name, "attached_node") ~= 0 then
		-- find an acceptable orientation
		for i = 1, 5 do
			if not check_attached_node(pos, rotation) then
				rotation = wallmounted_tbl[click][rotation] or 0
			else
				break
			end
		end
	end
	return rotation + other, "Wallmounted node rotated with default screwdriver behavior"
end

handlers.colorwallmounted = handlers.wallmounted

-- ============================================================
-- interaction

local function interact(player, pointed_thing, click)
	if pointed_thing.type ~= "node" then
		return
	end
	
	local pos = pointed_thing.under
	if minetest.is_protected(pos, player:get_player_name()) then
		notify(player, "You're not authorized to alter nodes in this area")
		minetest.record_protection_violation(pos, player:get_player_name())
		return
	end

	local node = minetest.get_node(pointed_thing.under)
	local nodedef = minetest.registered_nodes[node.name]

	if not nodedef then
		notify(player, "Unsupported node type: " .. node.name)
		return
	end

	local handler = handlers[nodedef.paramtype2]
		
	-- Node provides a handler, so let the handler decide instead if the node can be rotated
	if nodedef.on_rotate then
		-- Copy pos and node because callback can modify it
		local pass_node = {name = node.name, param1 = node.param1, param2 = node.param2}
		local pass_pos = vector.new(pos)
		local result = nodedef.on_rotate(pass_pos, pass_node, player, click, node.param2)
		if result == true then
			notify(player, "Rotation reportedly performed by on_rotate()")
			return
		else
			notify(player, "Rotation disallowed by on_rotate() return value")
			return
		end
	elseif nodedef.on_rotate == false then
		notify(player, "Rotation prevented by on_rotate == false")
		return
	elseif nodedef.can_dig and not nodedef.can_dig(pos, player) then
		notify(player, "Rotation prevented by can_dig() checks")
		return
	elseif not handler then
		notify(player, "Cannot rotate node with paramtype2 == " .. nodedef.paramtype2)
		return
	end
	
	local new_param2, handler_message = handler(node, player, pointed_thing, click)
	node.param2 = new_param2
	minetest.swap_node(pos, node)
	minetest.check_for_falling(pos)

	if handler_message then
		notify(player, handler_message)
	end
	
	return	
end

minetest.register_tool("rhotator:screwdriver", {
	description = "Rhotator Screwdriver (left-click pushes edge, right-click rotates face)",
	inventory_image = "rhotator.png",
	on_use = function(itemstack, player, pointed_thing)
		interact(player, pointed_thing, PRIMARY_BTN)
		return itemstack
	end,
	on_place = function(itemstack, player, pointed_thing)
		interact(player, pointed_thing, SECONDARY_BTN)
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
