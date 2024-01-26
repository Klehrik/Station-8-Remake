-- item

function obj_item(x, y, sprite, func, func2)
    local self = object()
    self:add_component(cmp_sprite)

    merge_tables(self, {

        -- Variables
        x = x * 8,
        y = y * 8 + 4,
        sprite = sprite,
        func = func,
        func2 = func2,


        -- Methods
        update_and_draw = function(self)
            -- Pick up item
            if self:hitbox_collision(player) then
                self.func()
                if (self.func2) self.func2()
                self:destroy()
            end

            -- Draw sprite inside circle
            local sine = sin(tick / 150)
            circfill(self.x + 4, self.y + 4, 6.5 + sine, 1)
            circ(self.x + 4, self.y + 4, 8.5 - sine, 13)
            spr(self.sprite, self.x, self.y + 1.5 - sine)
        end,


        destroy = function(self)
            del(world, self)
        end,
    })

    add(world, self)
    return self
end