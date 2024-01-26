-- game functions

function update_camera()
    local xTo, yTo = get_screen(player)
    local dx, dy = xTo - cam.x, yTo - cam.y
    cam.x += dx / cam.speedDiv
    cam.y += dy / cam.speedDiv
    if (abs(dx) < 0.5) cam.x = xTo
    if (abs(dy) < 0.5) cam.y = yTo
    cam.y = min(cam.y, 896)     -- Clamp y coord
    camera(cam.x, cam.y)
end

function draw_hud_elements()
    -- Player health
    for i = 1, player.hpMax do
        if (player.hp < i) pal(12, 1) pal(11, 1)
        if (player.hp == i) pal(12, 7) pal(11, 12)
        spr(50, cam.x + i * 6 - 2, cam.y + 4)
        set_palette()
    end

    -- Player equipment
    local table = {player.canShoot, player.jumpsMax > 1, player.canDash, player.canHover, 51, 53, 54, 58}
    for i = 1, 4 do
        if (table[i]) spr(table[i + 4], cam.x - 5 + i * 9, cam.y + 12)
    end
    if (player.canShoot and player.damageUp > 0) print("+"..player.damageUp, cam.x + 4, cam.y + 20, 13)

    -- Boss health bar
    if activeBoss then
        -- Name
        for i = 0, 1 do print(activeBoss.name, cam.x + 64 - #activeBoss.name*2 - i, cam.y + 108 - i, i * 6) end

        -- Border
        local _x, _y = cam.x + 6, cam.y + 114
        rect_wh(_x, _y, 116, 8, 0, true)
        rect_wh(_x, _y, 116, 8, 13)
        rect_wh(_x, _y + 9, 116, 1, 1)

        -- Filled part
        rect_wh(_x + 2, _y + 2, activeBoss.hp/activeBoss.hpMax * 112, 4, 8, true)
    end
end

function init_world()
    -- Reload map and tables
    map_import()
    objects, entities, projectiles, particles, world, activeBoss = {}, {}, {}, {}, {}, nil
    add_self(kazuma)
    add_self(player)

    -- Tiles to check
    local tiles = {}
    tiles[17], tiles[18], tiles[41], tiles[114], tiles[115], tiles[119] = obj_ceiling_enemy, obj_ground_enemy, obj_flying_enemy, obj_door, obj_door_locked, obj_save_point

    -- Loop through map
    for _y = 0, 127 do
        for _x = 0, 127 do
            local tile = mget(_x, _y)
            if tiles[tile] != nil then
                mset(_x, _y, 0)
                tiles[tile](_x, _y)
            end
        end
    end

    -- Terminals
    obj_terminal(121, 76, function()
        textManager:add_lines({"tHIS TERMINAL SEEMS TO BE^OPERATING ON #BACKUP POWER@.",
                                {"eNABLED *lEVEL 1 @ACCESS.", function()
                                    flags.level = set_bit(flags.level, 1)
                                end}})
    end)
    obj_terminal(6, 104, nil, 2, 12, true)
    obj_terminal(35, 54, function()
        textManager:add_lines({"tHIS TERMINAL SEEMS TO^CONTROL THE DOORS.",
                                {"oPENED ALL LOCKED DOORS.", function()
                                    flags.level = set_bit(flags.level, 4)
                                end}})
    end, 4, 8)

    -- Main power switch
    local f = function() for i = 0, 1 do mset(103 + i, 119, 124 + i) end end
    local t = obj_trigger(103, 119.75, function()
        textManager:add_lines({"iT APPEARS TO BE SWITCHED^OFF.",
                              {"tURNED ON #MAIN POWER@.", f}})
        flags.level = set_bit(flags.level, 3)
    end, 2, 0.25)
    if get_bit(flags.level, 3) then
        f()
        t:destroy()
    end


    --- Items

    function place_upgrade(x, y, sprite, num, func2)
        if (get_bit(flags.upgrades, num)) return
        obj_item(x, y, sprite, function() flags.upgrades = set_bit(flags.upgrades, num) end, func2)
    end

    -- Light Rifle
    place_upgrade(10, 73.5, 51, 1, function()
        player.canShoot = true
        textManager:add_lines({"pICKED UP &lIGHT rIFLE@.^hOLD #z @OR #c @TO FIRE.",
                               "yOU CAN FIRE IT^#UP @AND #DOWN @AS WELL."})
    end)

    -- Jump Boots
    place_upgrade(117, 75.5, 53, 2, function()
        player.jumpsMax = 2
        textManager:add_lines({"pICKED UP *jUMP bOOTS@.^yOU CAN NOW #JUMP TWICE@."})
    end)

    -- Dash Booster
    place_upgrade(122, 58.5, 54, 3, function()
        player.canDash = true
        textManager:add_lines({"pICKED UP *dASH bOOSTER@.^dOUBLE TAP #LEFT @OR #RIGHT",
                                "TO DASH IN THAT DIRECTION,^#EVADING ALL ATTACKS@."})
    end)

    -- Hoverpack
    place_upgrade(22.5, 59.5, 58, 4, function()
        player.canHover = true
        textManager:add_lines({"pICKED UP #hOVERPACK@.^hOLD #x @TO SLOWLY DESCEND."})
    end)

    -- Upgrades
    local pm, ru = split("118.5,86.5,54.5,104.5,89.5,35.5"), split("2.5,117.5,7.5,90.5,40.5,61.5")
    for i = 1, 6, 2 do
        -- Power Modules
        if not get_bit(flags.lifeUp, i) then
            obj_item(pm[i], pm[i+1], 52, function()
                flags.lifeUp = set_bit(flags.lifeUp, i)
                player.hp += 1
                player.hpMax += 1
                textManager:add_lines({"pICKED UP *pOWER mODULE@.^mAX #lIFE @INCREASED BY #1@."})
            end)
        end

        -- Rifle Upgrades
        if not get_bit(flags.damageUp, i) then
            obj_item(ru[i], ru[i+1], 55, function()
                flags.damageUp = set_bit(flags.damageUp, i)
                player.damageUp += 1
                textManager:add_lines({"pICKED UP &rIFLE uPGRADE@.^#dAMAGE @INCREASED BY #25%@."})
            end)
        end
    end


    --- Triggers

    -- Boss 1
    if not get_bit(flags.bossDown, 1) then
        obj_trigger(104, 70, function()
            local b = obj_boss_1(832, 504)  -- Spawn just offscreen
            textManager:add_lines({"uNKNOWN ENTITY DETECTED.^rESPONDING TO THREAT.", function() activeBoss = b end})
        end, 1, 7)
    end

    -- Boss 2
    if (not get_bit(flags.bossDown, 2)) obj_boss_2(704, 912)

    -- Boss 3
    if not get_bit(flags.bossDown, 3) then
        mset(121, 40, 181)
        obj_trigger(117, 33, function()
            local b = obj_boss_3(972, 324)
            textManager:add_lines({"..97%..",
                                   "..98%..^..99%..",
                                   "..#100%@.^rEACTIVATION COMPLETE.", function() activeBoss = b end})
            mset(121, 40, 0)
        end, 1, 12)
    end


    -- Intro/respawn text
    if not player.canShoot then
        textManager:add_lines({"uSE #ARROWS @TO MOVE.^hOLD #x @TO JUMP HIGHER.",
                               "pRESS #DOWN @AND #x ^@TO DROP DOWN PLATFORMS."})
        save_data(true, player.x, player.y)
    else textManager:add_lines({"rEBOOTING... ... ...^rEBOOT SEQUENCE SUCCESSFUL."})
    end
end

function update_world()
    -- Unlock the first room door if the gun is acquired
    if (player.canShoot) unlock_door(15, 71)

    -- Unlock level gates
    local _y = tick % 128
    for _x = 0, 127 do
        for i = 1, 2 do
            if (get_bit(flags.level, i) and mget(_x, _y) == 111 + i) mset(_x, _y, 116)
        end
    end

    -- Unlock locked doors
    if get_bit(flags.level, 4) then
        for d in all(world) do
            if (d.unlockable) d.locked = false
        end
    end
end

function save_data(savePosition, x, y)
    -- 01 - level
    -- 02 - bossDown
    -- 03 - upgrades
    -- 04 - lifeUp
    -- 05 - player hpMax
    -- 06 - player x
    -- 07 - player y
    -- 08 - kazuma state
    -- 09 - damageUp
    -- 10 - player damageUp

    poke(0x5e00, 1, flags.level, flags.bossDown, flags.upgrades, flags.lifeUp, player.hpMax)
    if (savePosition) poke(0x5e06, x \ 8, y \ 8)
    poke(0x5e08, kazuma.state, flags.damageUp, player.damageUp)
end

function load_data()
    if peek(0x5e00) == 1 then
        flags.level, flags.bossDown, flags.upgrades, flags.lifeUp = peek(0x5e01, 4)
        player:set_hp(peek(0x5e05))
        player.x, player.y = peek(0x5e06) * 8 + 4, peek(0x5e07) * 8 + 4
        kazuma.state, flags.damageUp, player.damageUp = peek(0x5e08, 3)

        -- Load upgrades
        if (get_bit(flags.upgrades, 1)) player.canShoot = true
        if (get_bit(flags.upgrades, 2)) player.jumpsMax = 2
        if (get_bit(flags.upgrades, 3)) player.canDash = true
        if (get_bit(flags.upgrades, 4)) player.canHover = true

        -- Set camera
        cam.x, cam.y = get_screen(player)
    end
end
