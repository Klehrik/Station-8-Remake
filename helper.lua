-- helper

function update_input_states()
    LEFT, RIGHT, UP, DOWN, O_DOWN, X_DOWN = btn(⬅️), btn(➡️), btn(⬆️), btn(⬇️), btn(🅾️), btn(❎)

    uis_xPressed += X_DOWN and 1 or -uis_xPressed
    uis_lPressed += LEFT and 1 or -uis_lPressed
    uis_rPressed += RIGHT and 1 or -uis_rPressed
    
    X_PRESSED = uis_xPressed == 1
    LEFT_PRESSED = uis_lPressed == 1
    RIGHT_PRESSED = uis_rPressed == 1
end

function in_table(table, value)
    for i in all(table) do
        if (i == value) return true
    end
    return false
end

function merge_tables(table1, table2)
    for k, v in pairs(table2) do table1[k] = v end
    return table1
end

function tile_flag(x, y, flag)
    return fget(mget(x \ 8, y \ 8), flag or 0)
end

function point_distance(x1, y1, x2, y2)
    local div = 16  -- higher values allow greater distance, but less accuracy
	return sqrt(((x2 - x1) / div)^2 + ((y2 - y1) / div)^2) * div
end

function rect_wh(x, y, w, h, col, filled)
    local func = filled and rectfill or rect
    func(x, y, x + w - 1, y + h - 1, col)
end

function in_view(obj)
    return obj.x > cam.x and obj.x < cam.x + 127 and obj.y > cam.y and obj.y < cam.y + 127
end

function get_screen(obj)
    -- Returns the top left x, y of the 128x128 screen the object is in
    return obj.x \ 128 * 128, obj.y \ 128 * 128
end

function ease_out(n)
    -- Cubic ease out
    return 1 - (1 - n)^3
end

function random(n1, n2)
    -- Returns an integer between n1 and n2 (inclusive)
    return n1 + flr(rnd(n2 - n1 + 1))
end

function print_fx(str, x, y, col)
    local col, xStart = col or 13, x
    for i = 1, #str do
        local char = str[i]
        if char == "^" then
            x = xStart
            y += 7
        elseif char == "@" then col = 13
        elseif char == "#" then col = 6
        elseif char == "&" then col = 12
        elseif char == "*" then col = 10
        else
            print(char, x, y, col)
            x += 4
        end
    end
end

function set_bit(n, pos)
    -- 8 positions
    -- leftmost bit is pos 1, and rightmost is pos 8
    return n | 2^(7-(pos-1))
end

function get_bit(n, pos)
    -- 8 positions
    -- leftmost bit is pos 1, and rightmost is pos 8
    local m = 2^(7-(pos-1))
    if (n & m == m) return true
    return false
end