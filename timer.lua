local has_armor_mod = minetest.get_modpath("3d_armor")
local use_player_monoids = minetest.global_exists("player_monoids")

local timer = 0

function update_gravity(player)
	local pos = player:get_pos()

	if not pos then
		-- yeah, it happens apparently :)
		return
	end

	local new_gravity = gravity_manager.get_gravity(pos)
	if use_player_monoids then
		if new_gravity then
			player_monoids.gravity:add_change(player, new_gravity, "gravity_manager:gravity")
		else
			player_monoids.gravity:del_change(player, "gravity_manager:gravity")
		end
	else
		local phys_override = player:get_physics_override()
		local current_gravity = phys_override.gravity

		if math.abs(current_gravity - new_gravity) > 0.01 then
			local name = player:get_player_name()
			minetest.log("action", "[gravity_manager] setting new gravity " .. new_gravity ..
				" for player: " .. name)
			player:set_physics_override({gravity=new_gravity})
		end
	end
end

if has_armor_mod and not use_player_monoids then
	-- update physics if armor changed
	armor:register_on_update(update_gravity)
end

minetest.register_on_joinplayer(function(player)
	minetest.after(0, function()
		update_gravity(player)
	end)
end)

minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < 0.5 then return end
	timer=0
	local t0 = minetest.get_us_time()

	local players = minetest.get_connected_players()
	for i, player in pairs(players) do
		update_gravity(player)
	end


	local t1 = minetest.get_us_time()
	local delta_us = t1 -t0
	if delta_us > 150000 then
		minetest.log("warning", "[gravity_manager] update took " .. delta_us .. " us")
	end
end)
