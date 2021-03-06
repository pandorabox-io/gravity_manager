local builtin_item = minetest.registered_entities["__builtin:item"]

-- If item_entity_ttl is not set, enity will have default life time
-- Setting it to -1 disables the feature

local time_to_live = tonumber(minetest.settings:get("item_entity_ttl")) or 900


local item = {

        on_activate = function(self, staticdata, dtime_s)
                if string.sub(staticdata, 1, string.len("return")) == "return" then
                        local data = minetest.deserialize(staticdata)
                        if data and type(data) == "table" then
                                self.itemstring = data.itemstring
                                self.age = (data.age or 0) + dtime_s
                                self.dropped_by = data.dropped_by
                        end
                else
                        self.itemstring = staticdata
                end

		local pos = self.object:get_pos()
		local gravity = gravity_manager.get_gravity(pos)

                self.object:set_armor_groups({immortal = 1})
                self.object:set_velocity({x = 0, y = 2, z = 0})
                self.object:set_acceleration({x = 0, y = -gravity, z = 0})
                self:set_item()
        end,


	set_item = function(self, itemstring)
		builtin_item.set_item(self, itemstring)

		local stack = ItemStack(itemstring)
		local itemdef = minetest.registered_items[stack:get_name()]
		if itemdef and itemdef.groups.flammable ~= 0 then
			self.flammable = itemdef.groups.flammable
		end
	end,

	burn_up = function(self)
		-- disappear in a smoke puff
		self.object:remove()
		local p = self.object:get_pos()
		minetest.sound_play("default_item_smoke", {
			pos = p,
			max_hear_distance = 8,
		})
		minetest.add_particlespawner({
			amount = 3,
			time = 0.1,
			minpos = {x = p.x - 0.1, y = p.y + 0.1, z = p.z - 0.1 },
			maxpos = {x = p.x + 0.1, y = p.y + 0.2, z = p.z + 0.1 },
			minvel = {x = 0, y = 2.5, z = 0},
			maxvel = {x = 0, y = 2.5, z = 0},
			minacc = {x = -0.15, y = -0.02, z = -0.15},
			maxacc = {x = 0.15, y = -0.01, z = 0.15},
			minexptime = 4,
			maxexptime = 6,
			minsize = 5,
			maxsize = 5,
			collisiondetection = true,
			texture = "default_item_smoke.png"
		})
	end,

	on_step = function(self, dtime)
		-- engine
		self.age = self.age + dtime
		if time_to_live > 0 and self.age > time_to_live then
			self.itemstring = ""
			self.object:remove()
			return
		end

		local pos = self.object:get_pos()
		local node = minetest.get_node_or_nil({
			x = pos.x,
			y = pos.y + self.object:get_properties().collisionbox[2] - 0.05,
			z = pos.z
		})
		-- Delete in 'ignore' nodes
		if node and node.name == "ignore" then
			self.itemstring = ""
			self.object:remove()
			return
		end

		local vel = self.object:get_velocity()
		local def = node and minetest.registered_nodes[node.name]
		local is_moving = (def and not def.walkable) or
			vel.x ~= 0 or vel.y ~= 0 or vel.z ~= 0
		local is_slippery = false

		if def and def.walkable then
			local slippery = minetest.get_item_group(node.name, "slippery")
			is_slippery = slippery ~= 0
			if is_slippery and (math.abs(vel.x) > 0.2 or math.abs(vel.z) > 0.2) then
				-- Horizontal deceleration
				local slip_factor = 4.0 / (slippery + 4)
				self.object:set_acceleration({
					x = -vel.x * slip_factor,
					y = 0,
					z = -vel.z * slip_factor
				})
			elseif vel.y == 0 then
				is_moving = false
			end
		end

		if self.moving_state == is_moving and
				self.slippery_state == is_slippery then
			print("ret early")
			-- Do not update anything until the moving state changes
			return
		end

		self.moving_state = is_moving
		self.slippery_state = is_slippery

		if is_moving then
			local gravity = gravity_manager.get_gravity(pos)
			print("grav: " .. gravity)
			self.object:set_acceleration({x = 0, y = -gravity, z = 0})
		else
			self.object:set_acceleration({x = 0, y = 0, z = 0})
			self.object:set_velocity({x = 0, y = 0, z = 0})
		end

		--Only collect items if not moving
		if is_moving then
			return
		end
		-- Collect the items around to merge with
		local own_stack = ItemStack(self.itemstring)
		if own_stack:get_free_space() == 0 then
			return
		end
		local objects = minetest.get_objects_inside_radius(pos, 1.0)
		for k, obj in pairs(objects) do
			local entity = obj:get_luaentity()
			if entity and entity.name == "__builtin:item" then
				if self:try_merge_with(own_stack, obj, entity) then
					own_stack = ItemStack(self.itemstring)
					if own_stack:get_free_space() == 0 then
						return
					end
				end
			end
		end

		-- default
		if self.flammable then
			-- flammable, check for igniters
			self.ignite_timer = (self.ignite_timer or 0) + dtime
			if self.ignite_timer > 10 then
				self.ignite_timer = 0

				node = minetest.get_node_or_nil(self.object:get_pos())
				if not node then
					return
				end

				-- Immediately burn up flammable items in lava
				if minetest.get_item_group(node.name, "lava") > 0 then
					self:burn_up()
				else
					--  otherwise there'll be a chance based on its igniter value
					local burn_chance = self.flammable
						* minetest.get_item_group(node.name, "igniter")
					if burn_chance > 0 and math.random(0, burn_chance) ~= 0 then
						self:burn_up()
					end
				end
			end
		end
	end
}

-- set defined item as new __builtin:item, with the old one as fallback table
setmetatable(item, builtin_item)
minetest.register_entity(":__builtin:item", item)
