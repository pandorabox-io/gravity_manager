
# Gravity manager for minetest

## Register custom gravity
```lua
-- low grav between y 1000 and 2000
gravity_manager.register({
	miny = 1000,
	maxy = 2000,
	gravity = 0.1
})
```

## Api

```lua
local gravity = gravity_manager.get_gravity(pos)
```