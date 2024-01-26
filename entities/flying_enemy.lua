-- entity : flying enemy

function obj_flying_enemy(x, y)
    local self = obj_entity(x * 8 + 4, y * 8 + 4)

    merge_tables(self, {

        -- Variables
        self:set_hp(7),
        collisionDamage = 1,

        frames = {41, 42},
        animationSpeed = 2,
        hitbox = {-2, -2, 1, 2},
        self:set_origin(),
        
        aggro = false,
        angle = 0,
        speed = 0,


        -- Methods
        update = function(self)
            if (not in_view(self)) self.aggro = false self.speed = 0 return

            if (not self.aggro and self:can_see_obj(player)) self.aggro = true self:set_alert_status(true)

            if self.aggro then
                local angle = self:point_to_obj(player)
                self.speed = min(self.speed + 0.01, 0.37)
                self.x += cos(angle) * self.speed
                self.y += sin(angle) * self.speed
                self.direction = player.x > self.x and 1 or -1
            end
        end,


        draw = function(self)
            -- Draw health bar and alert
            self:draw_health_bar()
            self:draw_alert_status()
        end,
    })

    add_self(self)
    return self
end