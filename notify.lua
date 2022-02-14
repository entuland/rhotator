local mod_name = minetest.get_current_modname()
local hud_name = ("%s_feedback"):format(mod_name)

local is_multicraft = minetest.get_version().project == "MultiCraft"

local hud_info_by_player_name = {}
local hud_timeout_seconds = 3

-- defaults
local position = { x = 0.1, y = 0.9}
local alignment = { x = 1, y = -1}
local normal_color = 0xFFFFFF
local warning_color = 0xFFFF00
local error_color = 0xDD0000
local direction = 0

local notify = {}
notify.__index = notify
setmetatable(notify, notify)

local function get_hud_def(message, params)
	local def = type(params) == "table" and params or {}
	def.position = def.position or position
	def.alignment = def.alignment or alignment
	def.number = def.number or def.color or normal_color
	def.color = nil
	def.position = def.position or position
	def.direction = def.direction or direction
	def.text = message or def.text
	def.hud_elem_type = def.hud_elem_type or "text"
	def.name = hud_name

	return def
end

local function hud_create(player, player_name, message, params)
	local def = get_hud_def(message, params)

	local id = player:hud_add(def)
	hud_info_by_player_name[player_name] = {
		id = id,
		timeout = os.time() + hud_timeout_seconds,
	}
end

local function hud_update(player, player_name, hud_id, message, params)
	local def = get_hud_def(message, params)

	for key, value in pairs(def) do
		-- multicraft has a bug that requires the "value" argument of hud_change to be a number
		if not is_multicraft or type(value) == "number" then
			player:hud_change(hud_id, key, value)
		end
	end

	hud_info_by_player_name[player_name] = {
		id = hud_id,
		timeout = os.time() + hud_timeout_seconds,
	}
end

minetest.register_globalstep(function()
	local now = os.time()

	for player_name, hud_info in pairs(hud_info_by_player_name) do
		if now > hud_info.timeout then
			local player = minetest.get_player_by_name(player_name)

			if player then
				local hud_def = player:hud_get(hud_info.id)
				if hud_def and hud_def.name == hud_name then
					player:hud_remove(hud_info.id)
				end
			end

			hud_info_by_player_name[player_name] = nil
		end
	end
end)

notify.warn = function(player, message)
	notify(player, message, {color = warning_color })
end

notify.warning = notify.warn

notify.err = function(player, message)
	notify(player, message, {color = error_color })
end

notify.error = notify.err

local function is_valid_player(player)
	return player
		and player.get_player_name
		and player.hud_get
		and player.hud_add
		and player.hud_change
		and player.hud_remove
end

notify.__call = function(self, player, message, params)
	local player_name
	if type(player) == "string" then
		player_name = player
		player = minetest.get_player_by_name(player_name)

	elseif is_valid_player(player) then
		player_name = player:get_player_name()
	end

	if not player and player_name then
		return
	end

	message = ("[%s] %s"):format(mod_name, message)

	local hud_info = hud_info_by_player_name[player_name]
	local hud_def

	if hud_info then
		hud_def = player:hud_get(hud_info.id)
	end

	if hud_def and hud_def.name == hud_name then
		hud_update(player, player_name, hud_info.id, message, params)

	else
		hud_create(player, player_name, message, params)
	end
end

return notify
