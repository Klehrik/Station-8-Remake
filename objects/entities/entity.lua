-- entity

function obj_entity(x, y)
    -- The base class for all entities
    
    local self = object()
    self:add_component(cmp_sprite)
    self:add_component(cmp_timers)
    self:add_component(cmp_health)

    return merge_tables(self, {

        -- Variables
        team = 2,
        
        x = x,
        y = y,

        alertText = "",
        alertY = 0,
        alertVsp = 0,
        alertCol = {0, 0},

        deathFunction = nil,


        -- Methods
        fire_bullet = function(self, dir, spd, col, offsetX, offsetY)
            local b = obj_bullet(self.x + (offsetX or 0), self.y + (offsetY or 0))
            b.dir, b.spd, b.team, b.col = dir, spd, self.team, col or 16 - self.team*4
            return b
        end,


        point_to_obj = function(self, target)
            return atan2(target.x - self.x, target.y - self.y)
        end,


        can_see_obj = function(self, target)
            if in_view(self) then
                local _x, _y, dir = self.x, self.y, self:point_to_obj(target)
                while point_distance(_x, _y, target.x, target.y) > 4 do
                    if (tile_flag(_x, _y)) return false
                    _x += cos(dir) * 4
                    _y += sin(dir) * 4
                end
                return true
            end
            return false
        end,


        draw_health_bar = function(self, y_offset)
            local _y = self.y + (y_offset or 6)
			rect_wh(self.x - 4, _y, 8, 1, 1)
			rect_wh(self.x - 4, _y, max(self.hp/self.hpMax * 8, 1), 1, 8)
		end,


        set_alert_status = function(self, alert)
            self.alertY, self.alertVsp = self:get_top_left().y - 4, 0.28
            self.alertText, self.alertCol = alert and "!" or "...", alert and {10, 4} or {6, 1}
        end,


        draw_alert_status = function(self)
            if self.alertVsp > 0 then
                self.alertY -= self.alertVsp
                self.alertVsp -= 0.008
                for i = 0, 1 do print(self.alertText, self.x - #self.alertText * 2 + i, self.alertY + i, self.alertCol[i + 1]) end
            end
        end,


        draw_gun_sprite = function(self, spr1, fr1, up, down)
            -- Used by the player and Boss 3
            local sprite, yoff = spr1, (self.sprite < fr1 or self.sprite > fr1 + 1) and 0 or -1
            if up then sprite = spr1 + 1
            elseif down then sprite = spr1 + 2 yoff += 1
            end
            if (not self.canShoot) sprite = 9   -- If player does not have the gun
            if (self.visible) spr(sprite, self:get_top_left().x, self:get_top_left().y + yoff, 1, 1, sgn(self.direction) != 1)
        end,


        draw_flash = function(self, col)
            -- Used by Boss 1 and 2
            circfill(self.x - random(0, 1), self.y - random(0, 1), 2, col)
        end,


        destroy = function(self)
			self.hp = 0
            part_destroy(self)
            if (self.deathFunction != nil) self.deathFunction()
            if activeBoss == self then
                activeBoss = nil
                destroy_projectiles()
            end
			del(objects, self)
			del(entities, self)
		end,
    })
end


function add_self(obj)
    add(objects, obj)
    add(entities, obj)
end