-- particle

function obj_particle(x, y, dir, spd, size, color, life, foreground)
    -- The main particle class

    -- If there are more than 80 particles, randomly cull 50% of them before production
    -- This is to prevent CPU overload
    if (#particles > 80 and rnd(1) < 0.5) return
    
    local self = {

        -- Variables
        x = x,
        y = y,

        dir = dir,
        speed = spd,
        size = size,
        col = color,
        life = life,
        lifeMax = life,
        
        foreground = foreground or false,


        -- Methods
        update = function(self)
            self.x += cos(self.dir) * self.speed
            self.y += sin(self.dir) * self.speed

            if self.life > 0 then self.life -= 1
            else self:destroy()
            end
        end,


        draw = function(self)
            circfill(self.x, self.y, self.life/self.lifeMax * self.size * 1.4, self.col)
        end,


        destroy = function(self)
            del(particles, self)
        end,
    }

    add(particles, self)
    return self
end


--------------------------------------------------
-- Particles

-- This is the next target for token optimization
-- Update Oct 19:   le epic fail

function part_bullet_collide(obj)
    for i = 1, 4 do obj_particle(obj.x, obj.y, rnd(1), rnd(0.4), 2, obj.col, random(12, 20), true) end
end

function part_bullet_travel(obj)
    if (tick % 2 == 0) obj_particle(obj.x, obj.y, atan2(obj.hsp, obj.vsp) - 0.6 + rnd(0.2), rnd(0.2), 1, obj.col, 2)
end

function part_jump(obj)
    for i = 1, 4 do obj_particle(obj.x, obj.y + 3, random(0, 1)/2 - 0.1 + rnd(0.2), rnd(0.3), 1, random(6, 7), random(12, 20)) end
end

function part_double_jump(obj)
    for i = 1, 4 do obj_particle(obj.x, obj.y, 0.6 + rnd(0.3), 0.3 + rnd(0.3), 2, random(9, 10), random(12, 20)) end
end

function part_dash(obj, dir)
    if (tick % 2 == 0) obj_particle(obj.x, obj.y, (0.25 - 0.25 * obj.dashDirection) - 0.6 + rnd(0.2), rnd(0.2), 2, random(9, 10), random(12, 20))
end

function part_destroy(obj)
    for i = 1, 6 do obj_particle(obj.x, obj.y, rnd(1), rnd(0.4), 3, random(6, 7), random(26, 34)) end
end