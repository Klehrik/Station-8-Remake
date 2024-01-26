-- entity : ceiling enemy

function obj_ceiling_enemy(x, y)
    local self = obj_entity(x * 8 + 4, y * 8 + 3)

    merge_tables(self, {

        -- Variables
        self:set_hp(6),

        frames = {17},
        hitbox = {-2, -3, 1, 0},
        self:set_origin(4, 3),
        
        aggro = false,
        self:set_timer(1, 90, 120),


        -- Methods
        update = function(self)
            if (not in_view(self)) self.aggro = false self:reset_timer() return
            
            if (not self.aggro and self:can_see_obj(player)) self.aggro = true self:set_alert_status(true)

            if self.aggro then
                if self:check_timer_and_reset(1, true) then
                    self:fire_bullet(self:point_to_obj(player), 0.8)
                end

                if not self:can_see_obj(player) and self:get_timer_percent() > 0.35 and self:get_timer_percent() < 0.6 then
                    self.aggro = false
                    self:reset_timer()
                    self:set_alert_status()
                end
            end
        end,


        draw = function(self)
            -- Flash before shooting
            if (self:get_timer_percent() <= 0.35) rectfill(self.x - 1, self.y - 2, self.x, self.y - 1, tick % 12 < 6 and 7 or 8)

            -- Draw health bar and alert
            self:draw_health_bar(3)
            self:draw_alert_status()
        end,
    })

    add_self(self)
    return self
end