-- entity : ground enemy

function obj_ground_enemy(x, y)
    local self = obj_entity(x * 8 + 4, y * 8 + 4)
    self:add_component(cmp_physics)

    merge_tables(self, {

        -- Variables
        self:set_hp(7),
        collisionDamage = 1,

        frames = {18},
        hitbox = {-2, -3, 1, 3},
        self:set_origin(),

        aggro = 0,
        self:set_timer(1, 45),


        -- Methods
        update = function(self)
            local dx, dy = abs(player.x - self.x), player.y - self.y

            -- Initial aggro
            if self.aggro == 0 and in_view(self) then
                self:decrease_timer()

                if (self:can_see_obj(player) and abs(dy) <= 4 and self:check_timer_and_reset()) or self.hurtThisFrame then
                    self.aggro = 1
                    self.direction = player.x > self.x and 1 or -1
                    self:set_timer(2, 45)
                    self:set_alert_status(true)
                end
            end

            if self.aggro > 0 then
                -- Charge delay
                if (self:check_timer(2, true)) self.aggro = 2
                
                -- Run towards player
                if self.aggro >= 2 then
                    self.hsp = self.hspMax * self.direction

                    -- Drop from platform
                    if (dy > 4 and (dx < 16 or self:tile_collision(0, sgn(self.hsp)))) self.ignorePlatforms = 6
                end

                -- Stop if player ends up behind
                if (self.direction == -1 and player.x > self.x) or (self.direction == 1 and player.x < self.x) or not in_view(self) then
                    self.aggro = 0
                    self:set_alert_status(false)
                end
            end

            -- Decelerate
            if (self.aggro < 2) self:decelerate()

            -- Switch animations
            self.frames = self.hsp == 0 and {18} or {19, 20, 21, 22}
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