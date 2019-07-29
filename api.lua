


-- def = { miny = 0, maxy = 1000, gravity = 0.5 }
gravity_manager.register = function(def)
	table.insert(gravity_manager.list, def)
end

gravity_manager.get_gravity = function(pos)
	for _,def in pairs(gravity_manager.list) do
		if pos.y > def.miny and pos.y < def.maxy then
			-- height match found
			return def.gravity
		end
	end

	return 1
end