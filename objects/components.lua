-- components

function object()
    -- The base class for all objects
    -- Contains the Component system

    return {
        components = {},

        add_component = function(self, component)
            name, cmp = component()
            add(self.components, name)
            merge_tables(self, cmp)
        end,

        has_component = function(self, name)
            return in_table(self.components, name)
        end,

        update = function() end,
        draw = function() end,
    }
end

function cmp_sprite()
    -- A component for handling many things related to an object's sprite,
    -- including drawing, animation, and hitboxes

    return "sprite", {

        -- Variables
        sprite = 0,             -- Current sprite
        frame = 1,              -- Current frame of animation
        frames = {0},           -- List of frames of animation
        animationSpeed = 5,     -- Frame delay between sprite switches
        visible = true,

        originX = 0,
        originY = 0,
        width = 1,              -- In terms of number of sprites (8 px. per)
        height = 1,
        direction = 1,

        hitbox = {0, 0, 7, 7},


        -- Methods
        draw_self = function(self)
            if (self.visible) spr(self.sprite, self:get_top_left().x, self:get_top_left().y, self.width, self.height, sgn(self.direction) != 1)
        end,


        animate = function(self)
			self.frame = max(((self.frame + 1/self.animationSpeed) % (#self.frames + 1)), 1)
			self.sprite = self.frames[flr(self.frame)]
		end,


        set_entity_size = function(self, w, h)
            self.width, self.height = w, h or w
        end,


        set_origin = function(self, ox, oy)
            self.originX, self.originY = ox or self.width * 4, oy or self.height * 4
        end,


        get_top_left = function(self)
            return {x = self.x - self.originX, y = self.y - self.originY}
        end,


        hitbox_collision = function(self, obj)
            return not (self.x + self.hitbox[1] > obj.x + obj.hitbox[3]
            or obj.x + obj.hitbox[1] > self.x + self.hitbox[3]
            or self.y + self.hitbox[2] > obj.y + obj.hitbox[4]
            or obj.y + obj.hitbox[2] > self.y + self.hitbox[4])
        end,
    }
end

function cmp_physics()
    -- A component for handling physics

    return "physics", {

        -- Variables
        hsp = 0,
        hspMax = 0.6,
        hspDecel = 0.1,
        vsp = 0,
        vspMax = 3,
        gravity = 0.1,

        -- applyForces = true,
        applyGravity = true,
        ignorePlatforms = 0,


        -- Methods
        apply_forces = function(self)
            -- Cap horizontal speed
			if (abs(self.hsp) > self.hspMax) self.hsp -= self.hspDecel * sgn(self.hsp)

            local loops = 0     -- This is only here because debug teleport to cursor will hang on some specific pixels
							    -- An infinite collision loop will never occur in normal gameplay

            -- Horizontal collision and movement
			if self:tile_collision(0, self.hsp) then
				while not self:tile_collision(0, sgn(self.hsp)) do
					self.x += sgn(self.hsp) * 0.1
                    loops += 1
					if (loops > 100) break
				end
				self.hsp = 0
			end
			self.x += self.hsp

            -- Apply gravity
            if (self.applyGravity) self.vsp += self.gravity

            -- Vertical collision and movement
			if self:tile_collision(0, 0, self.vsp) then
				while not self:tile_collision(0, 0, sgn(self.vsp)) do
					self.y += sgn(self.vsp) * 0.1
                    loops += 1
					if (loops > 100) break
				end
				self.vsp = 0
			end
            
            self.ignorePlatforms = max(self.ignorePlatforms - 1, 0)
            if self.ignorePlatforms <= 0 and self.vsp > 0 and not self:tile_collision(1) and self:tile_collision(1, 0, self.vsp) then
                while not self:tile_collision(1, 0, 1) do
					self.y += 0.1
                    loops += 1
					if (loops > 100) break
				end
				self.vsp = 0
			end

            self.vsp = min(self.vsp, self.vspMax)
			self.y += self.vsp
        end,


        decelerate = function(self)
            self.hsp -= self.hspDecel * sgn(self.hsp)
			if (abs(self.hsp) <= self.hspDecel) self.hsp = 0
        end,


        tile_collision = function(self, flag, offsetX, offsetY)
            for _y = 2, 4, 2 do
                for _x = 1, 3, 2 do
                    if (tile_flag(self.x + (offsetX or 0) + self.hitbox[_x], self.y + (offsetY or 0) + self.hitbox[_y], flag or 0)) return true
                end
            end
            return false
        end,


        is_grounded = function(self)
            return self:tile_collision(0, 0, 1) or (not self:tile_collision(1) and self:tile_collision(1, 0, 1))
        end,
    }
end

function cmp_timers()
    -- A component for handling timers

    return "timers", {

        -- Variables
        timers = {},


        -- Methods
        set_timer = function(self, index, maxTime, startTime)
            self.timers[index] = {startTime or maxTime, maxTime}
        end,


        reset_timer = function(self, index, val)
            -- Resets timer to maximum value by default, or to a specified value
            self.timers[index or 1][1] = val or self.timers[index or 1][2]
        end,


        decrease_timer = function(self, index)
            self.timers[index or 1][1] = max(self:get_timer(index or 1) - 1, 0)
        end,


        check_timer = function(self, index, decrease)
            -- Returns true if it reached 0
            if (decrease) self:decrease_timer(index or 1)
            return self:get_timer(index or 1) <= 0
        end,


        check_timer_and_reset = function(self, index, decrease)
            -- Returns true and resets the timer if it reached 0
            if (decrease) self:decrease_timer(index)
            if (self:check_timer(index)) self:reset_timer(index) return true
            return false
        end,


        get_timer = function(self, index)
            return self.timers[index or 1][1]
        end,


        get_timer_percent = function(self, index)
            return self:get_timer(index or 1) / self.timers[index or 1][2]
        end,
    }
end

function cmp_health()
    -- A component for handling health

    return "health", {

        -- Variables
        hp = 1,
        hpMax = 1,
        invulnerable = 0,
        invFrames = 0,

        collisionDamage = 0,
        hurtThisFrame = false,
        flashTime = 0,


        -- Methods
        set_hp = function(self, n)
            self.hp, self.hpMax = n, n
        end,


        is_invulnerable = function(self)
            return self.invulnerable > 0
        end,


        take_damage = function(self)
            self.hurtThisFrame = false

            -- Run destroy function
            if (self.hp <= 0) self:destroy()

            function hurt(dmg)
                self.hp -= dmg
                self.invulnerable, self.flashTime, self.hurtThisFrame = self.invFrames, max(self.invFrames, 10), true
            end

            -- Set sprite visibility
            self.flashTime = max(self.flashTime - 1, 0)
            if (self:has_component("sprite")) self.visible = self.flashTime % 4 < 2 and true or false

            -- Decrease invulnerability counter
            if (self:is_invulnerable()) self.invulnerable -= 1 return

            -- Instant death from falling out of the map (128 * 8 = 1024 + 64 = 1088)
			if (self.y > 1088) self:destroy()

            -- Check if self even in view
            if (not in_view(self)) return

            -- Projectile damage
            for p in all(projectiles) do
                if self.team != p.team and self:hitbox_collision(p) then
                    hurt(p.damage)
                    p:destroy()
                    return
                end
            end

            -- Collision damage
            for e in all(entities) do
                if self.team != e.team and e.collisionDamage > 0 and self:hitbox_collision(e) then
                    hurt(e.collisionDamage)
                    return
                end
            end

            -- Collision with spikes
            if (self:has_component("physics") and self:tile_collision(2)) hurt(1)
        end,
    }
end
