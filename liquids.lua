
-- liquids in zero-g

function create_zero_g_liquid(prefix, suffix)
	local def = minetest.registered_nodes[prefix .. ":" .. suffix]
	local defCopy = table.copy(def)

	defCopy.liquidtype = nil
	defCopy.liquid_alternative_flowing = nil
	defCopy.liquid_alternative_source = nil
	defCopy.liquid_viscosity = nil
	defCopy.liquid_renewable = nil
	defCopy.liquid_range = nil

	minetest.register_node("gravity_manager:" .. suffix, defCopy)

	-- TODO: swap original source to zero-g source
	-- TODO: swap zero-g source to original source

	if minetest.registered_nodes[prefix .. ":" .. suffix .. "_flowing"] then
		minetest.register_abm({
			label = "flowing liquid zero-g cleanup for " .. suffix,
			nodenames = {prefix .. ":" .. suffix .. "_flowing"},
			interval = 5,
			chance = 20,
			action = function(pos)
				-- TODO: check gravity and remove flowing liquid if in zero-g
			end
		})
	end

end


create_zero_g_liquid("default", "water_source")
create_zero_g_liquid("default", "river_water_source")
create_zero_g_liquid("default", "lava_water_source")

