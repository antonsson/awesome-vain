-- Grab environment.
local tonumber = tonumber
local beautiful = beautiful
local awful = awful
local math = math

module("vain.layout.centerworkd")

name = "centerworkd"

function arrange(p)

    -- A useless gap (like the dwm patch) can be defined with
    -- beautiful.useless_gap_width .
    local useless_gap = tonumber(beautiful.useless_gap_width)
    if useless_gap == nil
    then
        useless_gap = 0
    end

    -- Screen.
    local wa = p.workarea
    local cls = p.clients

    -- Width of main column?
    local t = awful.tag.selected(p.screen)
    local mwfact = awful.tag.getmwfact(t)

    if #cls > 0
    then
        -- Main column, fixed width and height.
        local c = cls[#cls]
        local g = {}
        local mainwid = math.floor(wa.width * mwfact)
        local slavewid = wa.width - mainwid
        local slaveLwid = math.floor(slavewid / 2)
        local slaveRwid = slavewid - slaveLwid

        g.height = wa.height - 2 * useless_gap
        g.width = mainwid
        g.x = wa.x + slaveLwid
        g.y = wa.y + useless_gap

        c:geometry(g)

        -- Auxiliary windows.
        if #cls > 1
        then
            local clientsLeft = math.floor(#cls / 2)
            local clientsRight = math.floor((#cls - 1) / 2)
            local slaveLeftHeight = math.floor(wa.height / clientsLeft)
            local slaveRightHeight = math.floor(wa.height / clientsRight)

            local at = 0
            for i = 1, #cls-1, 1
            do
                c = cls[i]
                g = {}

                if i % 2 == 1
                then
                    -- left slave
                    g.x = wa.x + useless_gap
                    g.width = slaveLwid - 2 * useless_gap

                    local order = math.floor(i / 2)
                    g.y = (wa.y + useless_gap) + order * (slaveLeftHeight + useless_gap)
                    g.height = slaveLeftHeight - useless_gap

                    if order == clientsLeft-1
                    then
                        g.height = wa.y + wa.height - g.y - useless_gap
                    end
                else
                    -- right slave
                    g.x = wa.x + slaveLwid + mainwid + useless_gap
                    g.width = slaveRwid - 2 * useless_gap

                    local order = math.floor((i-1) / 2)
                    g.y = wa.y + useless_gap + order * (slaveRightHeight + useless_gap)
                    g.height = slaveRightHeight - useless_gap

                    if order == clientsRight-1
                    then
                        g.height = wa.y + wa.height - g.y - useless_gap
                    end
                end

                c:geometry(g)

                at = at + 1
            end
        end
    end
end

-- vim: set et :
