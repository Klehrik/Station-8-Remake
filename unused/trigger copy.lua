-- trigger

function obj_trigger(x, y, func, w, h)
    local self = object()
    self:add_component(cmp_sprite)

    merge_tables(self, {

        -- Variables
        x = x * 8,
        y = y * 8,
        hitbox = {0, 0, w*8, h*8},
        func = func,


        -- Methods
        update_and_draw = function(self)
            -- Trigger function
            if self:hitbox_collision(player) then
                self.func()
                self:destroy()
            end
        end,


        destroy = function(self)
            del(world, self)
        end,
    })

    add(world, self)
    return self
end