-- main

function _init()
    cartdata("klehrik_station_remake_1")

    tick = 0

    flags = {
        level       = 0b00000000,
        bossDown    = 0b00000000,
        upgrades    = 0b00000000,
        lifeUp      = 0b00000000,
        damageUp    = 0b00000000,
    }

    -- Set palette
    set_palette()

    -- Create important characters
    player, kazuma = obj_player(44, 596), obj_kazuma(48, 832)

    -- Camera
    cam = {speedDiv = 12}
    cam.x, cam.y = get_screen(player)

    -- Text manager
    textManager = text_manager()

    -- Init input state press variables
    uis_xPressed, uis_lPressed, uis_rPressed = 0, 0, 0

    -- Load saved data and initialize world
    load_data()
    init_world()

    -- DEBUG
    poke(0x5f2d, 1)
    --menuitem(2, "kill active boss", function() if (activeBoss) activeBoss.hp = 0 end)
    --menuitem(3, "reload map", function() init_world() end)
    menuitem(4, "erase save", function() for i = 0, 10 do poke(0x5e00 + i, 0) end run() end)
end


function set_palette()
    pal()
    palt(0, false)
    palt(14, true)
    pal(2, 129, 1)
    pal(4, 131, 1)
    pal(11, 140, 1)
end


--------------------------------------------------

function _update60()
    tick += 1

    noText = not textManager:has_text()

    -- Buttons
    update_input_states()

    -- Update objects
    if noText then
        for obj in all(objects) do
            obj:update()

            -- Update standard physics
            if (obj:has_component("physics")) obj:apply_forces()
            
            -- Update health
            if (obj:has_component("health")) obj:take_damage()
        end
    end

    -- Update camera position
    update_camera()

    -- Update world state
    update_world()

    -- DEBUG: Temp player death
    if player.hp <= 0 then
        save_data()
        load_data()
        init_world()
    end
end


function _draw()
    -- Clear screen
    cls()

    -- Boss 2: Draw paths
    circ(704, 952, 40, 1)
    rect_wh(664, 912, 1, 80, 1)
    rect_wh(744, 912, 1, 80, 1)

    -- Draw map
    map(0, 0, 0, 0, 128, 128)

    -- Update and draw world elements
    for e in all(world) do e:update_and_draw() end

    -- Update and draw background particles
    for p in all(particles) do
        if (noText) p:update()
        if (not p.foreground) p:draw()
    end

    -- Draw objects
    for obj in all(objects) do
        if in_view(obj) then
            -- Draw sprites
            if obj:has_component("sprite") then
                if (noText) obj:animate()
                obj:draw_self()
            end

            obj:draw()
        end
    end

    -- Draw foreground particles
    for p in all(particles) do
        if (p.foreground) p:draw()
    end

    -- Draw HUD
    draw_hud_elements()

    -- Update and draw text
    textManager:update_and_draw()

    -- DEBUG
    local _x, _y = cam.x + stat(32), cam.y + stat(33)
    if (stat(34) > 0) player.x, player.y, player.vsp = _x, _y, 0
    circ(_x, _y, 1, 7)
end