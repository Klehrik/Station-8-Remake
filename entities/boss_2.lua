-- entity : boss 2

function obj_boss_2(x, y)
    local self = obj_entity(x, y)

    merge_tables(self, {

        -- Variables
        name = "aUTHORIZER",

        self:set_hp(52),

        frames = {14},
        hitbox = {-6, -5, 5, 5},
        self:set_entity_size(2),
        self:set_origin(),
        
        state = 0,
        shots = 0,
        angle = 0.25,
        angleDir = 1,
        halfLoops = 3,
        self:set_timer(1, 180), -- Laser
        self:set_timer(2, 12),  -- Half-loops delay

        electricFloor = false,

        deathFunction = function()
            textManager:add_lines({"aCCESS AUTHORIZED.^yOU MAY-MAY-MAY--"})
            flags.bossDown = set_bit(flags.bossDown, 2)
        end,


        -- Methods
        update = function(self)
            -- Pre-fight
            if self.state == 0 then
                self.invulnerable = 1
                if player.x >= self.x and in_view(self) then
                    self.state = 1
                    textManager:add_lines({"uNAUTHORIZED ACCESS ATTEMPT.^yOU MAY NOT PROCEED.", function() activeBoss = self end})
                end

            -- Attack 1: Move in circle and fire lasers
            elseif self.state == 1 then
                -- Move
                self.angle += 0.002 * self.angleDir
                self.x, self.y = 704 + cos(self.angle) * 40, 952 + sin(self.angle) * 40

                -- Shoot
                if self:check_timer_and_reset(1, true) then
                    self:fire_laser(self:point_to_obj(player))
                    self.electricFloor = true
                end

                -- Process half-loops
                self:decrease_timer(2)
                if (abs(sin(self.angle)) <= 0.01 and self:check_timer_and_reset(2)) self.halfLoops -= 1
                self:process_halfloops(2)

            -- Attack 2: Move in vertical path and fire lasers
            elseif self.state == 2 then
                -- Move
                self.y += self.angleDir * 0.5
                if (self.y <= 912 or self.y >= 992) self.angleDir *= -1 self.halfLoops -= 1

                -- Shoot
                if (self:check_timer(1, true) and tick % 6 == 0) self:fire_laser(0) self:fire_laser(0.5)

                -- Process half-loops
                if (abs(self.y - 952) <= 1) self:process_halfloops(1)

            end


            -- Spawn ground electricity
            if (self.electricFloor) self:spawn_proj(random(652, 756), 1004)
        end,


        draw = function(self)
            -- Flash before shooting
            if (self:get_timer_percent() <= 0.3) self:draw_flash(10)
        end,

        
        spawn_proj = function(self, x, y)
            local b = obj_bullet(x, y)
            b.team, b.col, b.life = self.team, 10, 6
        end,


        fire_laser = function(self, dir)
            -- Of course, much like last time, the "laser" is just a line of projectiles to save tokens and implementation
            local _x, _y, step = self.x, self.y, 6
            while not tile_flag(_x, _y) do
                self:spawn_proj(_x, _y)
                _x += cos(dir) * step
                _y += sin(dir) * step
            end
        end,


        process_halfloops = function(self, n)
            if self.halfLoops <= 0 then
                self.state, self.halfLoops, self.angleDir = n, random(n, n + 2), random(0, 1)*2 - 1
                self:reset_timer()
            end
        end,
    })

    add_self(self)
    return self
end