-- terminal

function obj_terminal(x, y, accessFlag, accessColor)
    local self = object()
    self:add_component(cmp_sprite)

    merge_tables(self, {

        -- Variables
        x = x * 8,
        y = y * 8,
        hitbox = {-1, 7, 8, 7},
        text = {},
        used = false,
        accessFlag = accessFlag or 1,
        accessColor = accessColor or 10,
        needsPower = false,
        func =  function()
                    textManager:add_lines({"tHIS TERMINAL SEEMS TO BE^OPERATING ON #BACKUP POWER@.",
                                        {"eNABLED *lEVEL 1 @ACCESS.", function()
                                            flags.level = set_bit(flags.level, 1)
                                        end}})
                end,


        -- Methods
        update_and_draw = function(self)
            if (get_bit(flags.level, self.accessFlag)) self.used = true

            -- Activate terminal
            if self:hitbox_collision(player) then
                if not self.used then
                    self.used = true
                    if (self.func) self.func()
                end
            else self.used = false
            end

            -- Draw frame
            rect_wh(self.x - 7, self.y - 23, 22, 22, 1)

            if not self.needsPower or get_bit(flags.level, 3) then
                -- Add scrolling text
                if (tick % 30 == 0 or #self.text < 10) add(self.text, random(3, 7))
                if (#self.text > 10) deli(self.text, 1)

                -- Draw scrolling text
                for i = 1, #self.text do
                    rect_wh(self.x - 5, self.y - 24 + i * 2, self.text[i], 1, 13)
                end

                -- Draw access square
                local col = get_bit(flags.level, self.accessFlag) and self.accessColor or 1
                rect_wh(self.x + 7, self.y - 9, 6, 6, col)
                rect_wh(self.x + 9, self.y - 7, 2, 2, col)
            end
        end,
    })

    add(world, self)
    return self
end