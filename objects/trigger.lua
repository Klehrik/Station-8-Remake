-- trigger

function obj_trigger(x, y, func, w, h, multiUse, draw, timer)
    local self = object()
    self:add_component(cmp_sprite)
    self:add_component(cmp_timers)

    merge_tables(self, {

        -- Variables
        x = x * 8,
        y = y * 8,
        hitbox = {0, 0, w*8, h*8},
        func = func,
        draw = draw or nil,
        multiUse = multiUse,
        self:set_timer(1, timer or 0),  -- Delay


        -- Methods
        update_and_draw = function(self)
            -- Trigger function
            if self:hitbox_collision(player) then
                if self:check_timer_and_reset() then
                    self:func()
                    if (not self.multiUse) self:destroy()
                end
            else self:decrease_timer()
            end

            -- Drawing stuff
            if (self.draw) self:draw()
        end,


        destroy = function(self)
            del(world, self)
        end,
    })

    add(world, self)
    return self
end


--------------------------------------------------
-- Special triggers

-- I'm actually slightly insane for reducing relatively
-- well organized files to this, but I need the tokens.

function obj_save_point(x, y)
    obj_trigger(x, y,
    function(self)  -- Function
        save_data(true, self.x, self.y)
        player.hp = player.hpMax
        textManager:add_lines({"#lIFE @RESTORED TO FULL.^#gAME SAVED@."})
    end,
    1, 1, true,
    function(self)  -- Draw
        spr(119, self.x, self.y)
        if (self:check_timer() or tick % 4 <= 1) spr(self:check_timer() and 120 or 121, self.x + 1, self.y - 3.5 + sin(tick / 150))
    end, 90)
end


function obj_terminal(x, y, func, accessFlag, accessColor, needsPower)
    local t = obj_trigger(x, y,
    function(self)  -- Function
        if not self.used and not get_bit(flags.level, self.accessFlag) then
            self.used = true
            if (self.func2) self.func2()
        end
    end,
    1, 1, true,
    function(self)  -- Draw
        -- Frame
        rect_wh(self.x - 7, self.y - 23, 22, 22, 1)

        if not self.needsPower or get_bit(flags.level, 3) then
            -- Add scrolling text
            if (tick % 30 == 0 or #self.text < 10) add(self.text, random(3, 7))
            if (#self.text > 10) deli(self.text, 1)

            -- Draw scrolling text
            for i = 1, #self.text do
                rect_wh(self.x - 5, self.y - 24 + i*2, self.text[i], 1, 13)
            end

            -- Draw access square
            pal(1, get_bit(flags.level, self.accessFlag) and self.accessColor or 1)
            spr(111, self.x + 7, self.y - 9)
            set_palette()
        end
    end, 90)
    
    -- Extra fields
    t.text, t.used, t.accessFlag, t.accessColor, t.needsPower, t.func2 = {}, false, accessFlag or 1, accessColor or 10, needsPower, func
end


function obj_item(x, y, sprite, func, func2)
    local t = obj_trigger(x, y,
    function(self)  -- Function
        self.func2()
        if (self.func3) self.func3()
    end,
    1, 1, false,
    function(self)  -- Draw
        local sine = sin(tick / 150)
        circfill(self.x + 4, self.y + 4, 6.5 + sine, 1)
        circ(self.x + 4, self.y + 4, 8.5 - sine, 13)
        spr(self.sprite, self.x, self.y + 1.5 - sine)
    end, 90)

    t.sprite, t.func2, t.func3 = sprite, func, func2
end