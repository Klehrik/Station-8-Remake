-- entity : boss 1

function obj_boss_1(x, y)
    local self = obj_entity(x, y)

    merge_tables(self, {

        -- Variables
        name = "sECURI-bOT",

        self:set_hp(44),
        collisionDamage = 1,

        frames = {10},
        animationSpeed = 3,
        hitbox = {-6, -5, 5, 5},
        self:set_entity_size(2),
        self:set_origin(),
        
        state = 1,
        shots = 0,
        self:set_timer(1, 90),  -- Movement
        self:set_timer(2, 12),  -- Shooting

        deathFunction = function()
            textManager:add_lines({"dAMAGE CRITICAL!^sHUTTING DOWN..."})
            flags.bossDown = set_bit(flags.bossDown, 1)
        end,


        -- Methods
        update = function(self)
            -- Attack 1: Rapid fire
            if self.state == 1 then
                if self:move_towards(832, 568) then     -- Move towards center top
                    if self:check_timer(1, true) then
                        if self.shots < 12 then
                            if self:check_timer_and_reset(2, true) then
                                self.shots += 1
                                self:fire_bullet(self:point_to_obj(player), 0.8)
                            end
                        else
                            self.state, self.shots = 2, 0
                            self:set_timer(1, 40)
                        end
                    end
                end

            -- Attack 2a: Target player position
            elseif self.state == 2 then
                if self:check_timer(1, true) then
                    if self.shots < 3 then self.state, self.xTo, self.yTo = 3, player.x, player.y
                    else
                        self.state, self.shots = 1, 0
                        self:set_timer(1, 40)
                    end
                end
            
            -- Attack 2b: Ram into player and shoot
            elseif self.state == 3 then
                if self:move_towards(self.xTo, self.yTo) then
                    if self:check_timer_and_reset(2, true) then
                        self.state = 2
                        self.shots += 1
                        self:fire_bullet(self:point_to_obj(player), 0.8)
                        self:set_timer(1, 60)
                    end
                end

            end
        end,


        draw = function(self)
            -- Flash before shooting
            if (self:get_timer(2) <= 10) self:draw_flash(8)
        end,


        move_towards = function(self, x, y)
            if point_distance(self.x, self.y, x, y) < 1 then
                self.x, self.y, self.frames = x, y, {10}
                return true
            end
            self.x += (x - self.x) / 32
            self.y += (y - self.y) / 32
            self.frames = {10, 12}
            return false
        end,
    })

    add_self(self)
    return self
end