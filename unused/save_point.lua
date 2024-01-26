-- save point

-- Unused now

function obj_save_point(x, y)
    local self = object()
    self:add_component(cmp_sprite)
    self:add_component(cmp_timers)

    merge_tables(self, {

        -- Variables
        x = x * 8,
        y = y * 8,
        hitbox = {-1, 7, 8, 7},
        self:set_timer(1, 90),  -- Delay


        -- Methods
        update_and_draw = function(self)
            -- Restore player health and save game
            if self:hitbox_collision(player) then
                if self:check_timer_and_reset() then
                    save_data(true, self.x, self.y)
                    player.hp = player.hpMax
                    textManager:add_lines({"#lIFE @RESTORED TO FULL.^#gAME SAVED@."})
                end
            else self:decrease_timer()
            end

            -- Floppy disk over stand
            spr(119, self.x, self.y)
            if (self:check_timer() or tick % 4 <= 1) spr(self:check_timer() and 120 or 121, self.x + 1, self.y - 3.5 + sin(tick / 150))
        end,
    })

    add(world, self)
    return self
end