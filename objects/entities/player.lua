-- entity : player

function obj_player(x, y)
    local self = obj_entity(x, y)
    self:add_component(cmp_physics)

    merge_tables(self, {

        -- Variables
        team = 1,

        self:set_hp(4),
        invFrames = 60,

        sprite = 1,
        frames = {2, 3, 4, 5},
        hitbox = {-2, -3, 1, 3},
        self:set_origin(),

        jumpHeight = 1.87,
        jumps = 0,
        jumpsMax = 1,

        self:set_timer(5, 6),       -- Coyote time
        self:set_timer(6, 6, 0),    -- Jump buffer

        canShoot = false,
        damageUp = 0,
        self:set_timer(1, 15),      -- Shoot

        canDash = false,
        dashDirection = 0,
        dashMultiplier = 2.5,
        self:set_timer(2, 30, 0),   -- Dash cooldown
        self:set_timer(3, 15, 0),   -- Dash input time
        self:set_timer(4, 15, 0),   -- Dash time

        canHover = false,


        -- Methods
        update = function(self)
            -- Horizontal movement
            if ((LEFT or RIGHT) and not (LEFT and RIGHT)) then
                self.hsp = RIGHT and self.hspMax or -self.hspMax

                -- Flip sprite direction
                self.direction = RIGHT and 1 or -1
            else self:decelerate()
            end

            -- Platformer QoL
            self:decrease_timer(5)
            self:decrease_timer(6)
            if (self:check_timer(5) and self.jumps == self.jumpsMax) self.jumps -= 1
            if self:is_grounded() then
                self:reset_timer(5)
                self.jumps = self.jumpsMax
            end
            if (X_PRESSED) self:reset_timer(6)

            -- Jump or drop down platform
            if not self:check_timer(6) then
                if DOWN and self:tile_collision(1, 0, 2 + abs(self.vsp)) then
                    self:reset_timer(6, 0)
                    self.ignorePlatforms = 6
                else
                    if self.jumps > 0 then
                        self:reset_timer(6, 0)
                        self.vsp = -self.jumpHeight
                        if self.jumps < self.jumpsMax then
                            self.vsp += -self.jumpHeight * 0.05
                            part_double_jump(self)
                        else part_jump(self)
                        end
                        self.jumps -= 1
                    end
                end
            end

            -- Release jump early for short hop
            if (not X_DOWN and self.vsp < 0) self.vsp /= 1.15
            
            -- Hover
            if self.canHover and X_DOWN and self.vsp > 0 then
                self.vsp = min(self.vsp, self.vspMax/30)
                if (tick % 8 == 0) part_jump(self)
            end

            -- Dash
            self:decrease_timer(2)
            if self.canDash and self:check_timer(4) and self:check_timer(2) then
                self:decrease_timer(3)

                function check_dir(val)
                    if (self.dashDirection == val and not self:check_timer(3)) self:reset_timer(4)
                    self.dashDirection = val
                    self:reset_timer(3)
                end

                if (LEFT_PRESSED) check_dir(-1)
                if (RIGHT_PRESSED) check_dir(1)
            end

            -- Dash state
            if not self:check_timer(4) then
                self:decrease_timer(4)
                self.hsp, self.vsp, self.applyGravity = self.hspMax * self.dashMultiplier * self.dashDirection, 0, false
                self.invulnerable = max(self.invulnerable, 5)   -- Gives a total of 20 frames of invulnerability (5 after the state ends)

                if self:check_timer(4) then
                    self.dashDirection, self.applyGravity = 0, true
                    self:reset_timer(2)
                end
                
                part_dash(self)
            end

            -- Shoot
            self:decrease_timer()
            if O_DOWN and self.canShoot then
                if self:check_timer_and_reset() then
                    local dir = UP and 0.25 or DOWN and 0.75 or self.direction == 1 and 0 or 0.5
                    self:fire_bullet(dir, 3).damage = 1 + (self.damageUp * 0.251)
                end
            end

            -- Switch animations
            self.frames = self.hsp == 0 and {1} or {2, 3, 4, 5}
            if (not self:is_grounded()) self.frames = self.vsp <= 0 and {3} or {4}
        end,


        draw = function(self)
            -- Gun sprite
            self:draw_gun_sprite(6, 3, UP, DOWN)
        end,
    })
    
    return self
end