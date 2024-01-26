-- entity : kazuma

function obj_kazuma(x, y)
    local self = obj_entity(x, y)
    self:add_component(cmp_physics)

    merge_tables(self, {

        -- Variables
        frames = {33},
        animationSpeed = 20,

        state = 0,
        self:set_timer(1, 180), -- Typing


        -- Methods
        update = function(self)
            self.invulnerable = 1

            local inRange = player.x <= self.x + 26 and in_view(self)

            -- Dialogue
            if inRange and self.state == 0 then
                if not get_bit(flags.level, 3) then
                    self.state = 1
                    textManager:add_lines({"h-hUH? a ROBOT!?^w-wAIT!",
                                            "...oH. wHEW. yOU DON'T SEEM^TO BE HOSTILE.",
                                            "(mAYBE i CAN MAKE USE OF^IT...?)",
                                            "mOST OF THE POWER SEEMS TO^BE OFF, INCLUDING THIS.",
                                            "tHE MAIN CIRCUIT SWITCHES^ARE ON THE #RIGHT SIDE",
                                            "#OF THE FACILITY@, NOT TOO^FAR FROM HERE.",
                                            "cOULD YOU GO AND^REACTIVATE THE #MAIN POWER@?"})
                else
                    self.state = 2
                    textManager:add_lines({"h-hUH? a ROBOT!?^w-wAIT!",
                                            "...oH. wHEW. yOU DON'T SEEM^TO BE HOSTILE.",
                                            "wAIT, DID YOU REACTIVATE^THE #MAIN POWER@?",
                                            "nICE WORK! i'M GOING TO^ENABLE &lEVEL 2 @ACCESS NOW."})
                end

            elseif inRange and self.state == 1 and get_bit(flags.level, 3) then
                self.state = 2
                textManager:add_lines({"oH, YOU'RE FINALLY BACK!",
                                        "nICE WORK! i'M GOING TO^ENABLE &lEVEL 2 @ACCESS NOW."})

            elseif self.state == 2 then
                function wall(n)
                    for i = 101, 104 do mset(10, i, n) end
                end

                self.frames = self:get_timer() <= 30 and {33} or {34, 35}
                wall(127)

                if (self:get_timer() <= 30) flags.level = set_bit(flags.level, 2)
                if self:check_timer(1, true) then
                    self.state = 3
                    wall(0)
                    textManager:add_lines({"aLRIGHT, IT'S DONE.^yOU SHOULD BE ABLE TO",
                                            "REACH THE #cONTROL rOOM @NOW.",
                                            "iT'S LOCATED IN THE #UPPER^LEFT @SECTION, ACCESSABLE",
                                            "THROUGH THE #CENTRAL SHAFT@.",
                                            "fROM THERE, YOU'LL BE ABLE^TO OPEN THE #STATION HATCH@.",
                                            "tHEN WE CAN FINALLY GET^OUT OF HERE.",
                                            "i'LL GIVE YOU THIS TOO--^iT'S A TRANSMITTER.",
                                            "i CAN RELAY INSTRUCTIONS^TO YOU THROUGH IT.",
                                            "∧  lIKE THIS!^∧  gOOD LUCK!"})
                end

            elseif self.state == 3 then
                if self.trigger == nil then
                    self.trigger = obj_trigger(68, 68, function()
                        textManager:add_lines({"∧  nICE, YOU MADE IT OVER!^∧  jUST HEAD UP THERE.", function() kazuma.state = 4 kazuma.trigger = nil end})
                    end, 1, 4)
                end

            elseif self.state == 4 then
                if self.trigger == nil then
                    self.trigger = obj_trigger(77, 2, function()
                        textManager:add_lines({"∧  hUH, THAT'S A LARGE GAP.^∧  i DON'T THINK YOU'LL BE",
                                                "∧  ABLE TO CROSS IT, EVEN^∧  WTIH A *dASH bOOSTER@.",
                                                "∧  tHERE IS A #STORAGE^@∧  #ROOM @CLOSE BY THOUGH.",
                                                "∧  lOOK AROUND AND SEE IF^∧  YOU CAN FIND SOMETHING.",
                                                function() kazuma.state = 5 kazuma.trigger = nil end})
                    end, 1, 9)
                end

            end
        end,
    })
    
    return self
end