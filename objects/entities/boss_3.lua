-- entity : boss 3

function obj_boss_3(x, y)
    local self = obj_entity(x, y)
    self:add_component(cmp_physics)

    merge_tables(self, {

        -- Variables
        name = "sCOUT mODEL g-14",

        self:set_hp(58),
        collisionDamage = 1,

        frames = {36},
        hitbox = {-2, -3, 1, 3},
        self:set_origin(),

        jumpHeight = 2.25,
        
        state = 1,
        move = -1,
        shootDirection = 0,
        shots = 0,
        self:set_timer(1, 90),  -- Delay before jumping or dropping down
        self:set_timer(2, 90),  -- Random delay between moving
        self:set_timer(3, 600), -- Delay before Attack 2
        self:set_timer(4, 120), -- Attack 2 charge

        canShoot = true,

        deathFunction = function()
            textManager:add_lines({"sYSTEM ERROR.^rEBOOTING....  ..1%.."})
            flags.bossDown = set_bit(flags.bossDown, 3)
        end,


        -- Methods
        update = function(self)
            local dx, dy, angle = abs(player.x - self.x), player.y - self.y, self:point_to_obj(player)
            self.offsetX, self.offsetY = cos(angle)*4, sin(angle)*4

            -- Face direction of player
            self.direction, self.shootDirection = player.x > self.x and 1 or -1, flr((angle + 0.125) * 4) / 4

            -- Attack 1: Run and gun
            if self.state == 1 then
                -- Toggle movement
                if self:check_timer(2, true) then
                    self.move *= -1
                    self:set_timer(2, random(40, 80))
                end

                -- Move towards player
                if self.move == 1 and dx > 4 then self.hsp = self.hspMax * self.direction
                else self:decelerate()
                end

                -- Jump up/drop down platforms
                if abs(dy) > 12 and self:check_timer_and_reset(1, true) then
                    if dy < 0 then self.vsp = -self.jumpHeight
                    else self.ignorePlatforms = 6
                    end
                end

                -- Shoot
                if (self.move == 1 and tick % 15 == 0 and self:is_grounded()) self:fire_bullet(self.shootDirection, 2)

                -- Switch to Attack 2
                if (self:check_timer_and_reset(3, true)) self.state = 2

            -- Attack 2: Fire big bullets
            elseif self.state == 2 then
                -- Shoot
                self:decelerate()
                if self:check_timer_and_reset(4, true) then
                    if self.shots < 3 then
                        self.shots += 1
                        fire_big_bullet(self.x + self.offsetX, self.y + self.offsetY, angle, 0.8, self.team, 8)
                    else self.state, self.shots = 1, 0
                    end
                end

            end

            -- Switch animations
            self.frames = self.hsp == 0 and {36} or {37, 38, 39, 40}
            if (not self:is_grounded()) self.frames = self.vsp <= 0 and {38} or {39}
        end,


        draw = function(self)
            -- Gun sprite
            self:draw_gun_sprite(23, 38, self.shootDirection == 0.25, self.shootDirection == 0.75)

            -- Big bullet charge
            if self.state == 2 and self.shots < 3 then
                circfill(self.x + self.offsetX, self.y + self.offsetY, (1 - self:get_timer_percent(4)) * 4, 8)
            end
        end,
    })

    add_self(self)
    return self
end