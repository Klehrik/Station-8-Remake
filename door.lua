-- door

function obj_door(x, y, locked)
    local self = object()
    self:add_component(cmp_sprite)

    merge_tables(self, {

        -- Variables
        x = x * 8,
        y = y * 8,
        height = 0,
        heightMax = 0,
        locked = locked,
        unlockable = locked,


        -- Methods
        update_and_draw = function(self)
            -- Open door if player is near
            local open = (not self.locked and self:hitbox_collision(player) and not activeBoss) and true or false

            -- Increment/decrement height
            self.height = mid(self.height + (open and -2 or 2), 0, self.heightMax)

            -- Draw door
            for i = self.height-2, -2, -2 do sspr(16, 56, 8, 4, self.x, self.y + i) end

            -- Show door status
            rect_wh(self.x + 2, self.y - 3, 4, 1, (self.locked or activeBoss) and 8 or 12)

            -- Set collision tiles
            for i = 0, self.heightMax, 8 do mset(self.x \ 8, (self.y + i) \ 8, open and 0 or 127) end
        end,
    })

    -- Calculate endpoint of door
    while (not tile_flag(self.x, self.y + self.heightMax + 2)) self.heightMax += 2
    self.hitbox = {-8, 0, 16, self.heightMax}

    add(world, self)
    return self
end


function obj_door_locked(x, y)
    obj_door(x, y, true)
end

function unlock_door(mx, my)
	for d in all(world) do
		if (d.x == mx * 8 and d.y == my * 8) d.locked = false
	end
end