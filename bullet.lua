-- bullet

function obj_bullet(x, y)
    -- The main projectile class

    local self = object()

    merge_tables(self, {

        -- Variables
        team = 0,
        col = 6,
        
        x = x,
        y = y,
        dir = 0,
        spd = 0,

        damage = 1,

        frames = {48, 49},
        hitbox = {-2, -2, 1, 1},
        visible = true,

        life = 240,
        func = nil,


        -- Methods
        update = function(self)
            self.hsp, self.vsp = cos(self.dir) * self.spd, sin(self.dir) * self.spd
            self.x += self.hsp
            self.y += self.vsp

            if (tile_flag(self.x + self.hsp/2, self.y + self.vsp/2)) self:destroy()

            -- Destroy if lifetime is exceeded
            self.life -= 1
            if (self.life <= 0) self:destroy()
        end,


        draw = function(self)
            if self.visible then
                pal(12, self.col)
                spr(tick % 12 < 6 and self.frames[1] or self.frames[2], self.x - 4, self.y - 4)
                pal(12, 12)
                
                part_bullet_travel(self)
            end
        end,


        destroy = function(self)
            if (self.func) self:func()
            if (self.visible) part_bullet_collide(self)
            del(objects, self)
            del(projectiles, self)
        end,
    })

    add(objects, self)
    add(projectiles, self)
    return self
end


function fire_big_bullet(x, y, dir, spd, team, col)
    -- Explodes into a ring of bullets on collision

    local b = obj_bullet(x, y)
    b.frames, b.dir, b.spd, b.team, b.col, b.hitbox = {56, 57}, dir, spd, team, col, {-3, -3, 2, 2}
    b.func = function(self)
        for a = 0, 1, 0.05 do
            local c = obj_bullet(b.x - (self.hsp or 0), b.y - (self.vsp or 0))
            c.dir, c.spd, c.team, c.col = a, spd, team, col
        end
    end
    return b
end

function destroy_projectiles()
    for p in all(projectiles) do p:destroy() end
end