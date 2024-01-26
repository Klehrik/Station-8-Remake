-- text

function text_manager()
    local self = {

        -- Variables
        text = {},          -- Each line is a table containing the text and a function to run at the beginning
        char = 0,           -- Current character of line
        charSpeed = 0.4,    -- Speed of text scrolling (in characters per frame)

        y = 102,            -- y position of top of frame
        open = 0,           -- State of frame opening animation (from 0 to 1)
        openSpeed = 1/30,   -- Speed that the window opens


        -- Methods
        update_and_draw = function(self)
            -- Open/close frame
            local dir = self:has_text() and self.openSpeed or -self.openSpeed
            self.open = mid(self.open + dir, 0, 1)

            local width = ease_out(self.open) * 114
            local _x, _y = cam.x + 64 - width/2, cam.y + self.y

            -- Draw frame
            if self.open > 0 then
                rect_wh(_x, _y, width, 20, 0, true)
                rect_wh(_x, _y, width, 20, 13)
                rect_wh(_x, _y + 21, width, 1, 1)
            end

            if self.open >= 1 then
                local l = self.text[1]
                local e = #l[1]

                -- Run function
                if (self.char <= 0 and l[2] != nil) l[2]()

                -- Draw text
                self.char += self.charSpeed
                print_fx(sub(l[1], 1, self.char), cam.x + 11, _y + 4)

                -- Skip to end of text
                if (X_PRESSED) self.char = e

                -- Progress text
                if (btnp(🅾️) and self.char >= e) or e <= 0 then
                    self.char = 0
                    deli(self.text, 1)
                end
            end
        end,


        add_lines = function(self, lines)
            for i = 1, #lines do
                local l = lines[i]
                local l2 = type(l) == "string" and {l, nil} or type(l) == "function" and {"", l} or l
                add(self.text, l2)
            end
        end,


        has_text = function(self)
            return #self.text > 0
        end,
    }

    return self
end