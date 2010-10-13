-- Grab environment.
local awful = awful
local widget = widget
local timer = timer
local string = string
local beautiful = beautiful
local image = image
local io = io
local math = math
local os = os
local pairs = pairs
local vain = vain

module("vain.widgets")

-- System load
function systemload()
    local mysysload = widget({ type = "textbox" })
    local mysysloadupdate = function()
        local f = io.open("/proc/loadavg")
        local ret = f:read("*all")
        f:close()

        local a, b, c = string.match(ret, "([^%s]+) ([^%s]+) ([^%s]+)")
        mysysload.text = string.format("%s %s %s", a, b, c)
        mysysload.text = ' <span color="' .. beautiful.fg_urgent .. '">'
                         .. mysysload.text .. '</span> '
    end
    mysysloadupdate()
    local mysysloadtimer = timer({ timeout = 10 })
    mysysloadtimer:add_signal("timeout", mysysloadupdate)
    mysysloadtimer:start()
    return mysysload
end

-- Maildir check
function mailcheck(mailpath, ignore_boxes)
    local mymailcheck = widget({ type = "textbox" })
    local mymailcheckupdate = function()
        -- Default mail path?
        if mailpath == nil
        then
            mailpath = os.getenv("HOME") .. "/Mail"
        else
            mailpath = mailpath
        end

        -- Search for files in "new" directories. Print only their base
        -- path.
        local p = io.popen("find " .. mailpath ..
                           " -path '*/new/*' -type f -printf '%h\n'")
        local boxes = {}
        local line = ""
        repeat
            line = p:read("*l")
            if line ~= nil
            then
                -- Strip off leading mailpath and anything after and
                -- including "/new...". Save only unique boxes.
                local box = string.match(line, mailpath ..
                                               "/*\.?([^/]+)/new.*")
                if boxes[box] == nil
                then
                    boxes[box] = 1
                end
            end
        until line == nil

        local newmail = ""
        for box, dummy in pairs(boxes)
        do
            -- Add this box only if it's not to be ignored.
            if ignore_boxes ~= nil
               and not vain.util.element_in_table(box, ignore_boxes)
            then
                if newmail == ""
                then
                    newmail = box
                else
                    newmail = newmail .. ", " .. box
                end
            end
        end

        if newmail == ""
        then
            mymailcheck.text = " no mail "
        else
            mymailcheck.text = ' <span color="#FF0000">mail: '
                               .. newmail .. '</span> '
        end
    end
    mymailcheckupdate()
    local mymailchecktimer = timer({ timeout = 30 })
    mymailchecktimer:add_signal("timeout", mymailcheckupdate)
    mymailchecktimer:start()
    return mymailcheck
end

-- Battery
function battery()
    local mybattery = widget({ type = "textbox" })
    local mybatteryupdate = function()

        local first_line = vain.util.first_line
        local present = first_line("/sys/class/power_supply/BAT0/" ..
                                   "present")
        if present == "1"
        then
            local rate = first_line("/sys/class/power_supply/BAT0/" ..
                                    "current_now")
            local ratev = first_line("/sys/class/power_supply/BAT0/" ..
                                     "voltage_now")
            local rem = first_line("/sys/class/power_supply/BAT0/" ..
                                   "charge_now")
            local tot = first_line("/sys/class/power_supply/BAT0/" ..
                                   "charge_full")
            local status = first_line("/sys/class/power_supply/BAT0/" ..
                                      "status")

            local time_rat = 0
            if status == "Charging"
            then
                status = "(+)"
                time_rat = (tot - rem) / rate
            elseif status == "Discharging"
            then
                status = "(-)"
                time_rat = rem / rate
            else
                status = "(.)"
            end

            local hrs = math.floor(time_rat)
            local min = (time_rat - hrs) * 60
            local time = string.format("%02d:%02d", hrs, min)

            local perc = string.format("%d%%", (rem / tot) * 100)

            local watt = string.format("%.2fW", (rate * ratev) / 1e12)

            text = watt .. " " .. perc .. " " .. time .. " " .. status
        else
            text = "no battery"
        end

        mybattery.text = ' <span color="' .. beautiful.fg_urgent .. '">'
                         .. text .. '</span> '
    end
    mybatteryupdate()
    local mybatterytimer = timer({ timeout = 30 })
    mybatterytimer:add_signal("timeout", mybatteryupdate)
    mybatterytimer:start()
    return mybattery
end

-- Volume
function volume(mixer_channel, terminal)
    local myvolume = widget({ type = "textbox" })
    local myvolumeupdate = function()
        -- Mostly copied from vicious.
        local f = io.popen("amixer get " .. mixer_channel)
        local mixer = f:read("*all")
        f:close()

        local volu, mute = string.match(mixer, "([%d]+%%).*%[([%l]*)")

        if volu == nil
        then
            volu = 0
        end

        if mute == nil
        then
            mute = "---"
        end

        local ret = string.format("%s %s", volu, mute)
        myvolume.text = ' <span color="' .. beautiful.fg_urgent .. '">'
            .. ret .. '</span> '
    end
    myvolumeupdate()
    local myvolumetimer = timer({ timeout = 2 })
    myvolumetimer:add_signal("timeout", myvolumeupdate)
    myvolumetimer:start()
    myvolume:buttons(awful.util.table.join(
        awful.button({}, 1,
            function()
                awful.util.spawn('amixer set ' .. mixer_channel ..
                                 ' toggle')
             end),

        awful.button({}, 2,
            function()
                awful.util.spawn(terminal .. ' -e alsamixer')
            end),

        awful.button({}, 3,
            function()
                awful.util.spawn('amixer set ' .. mixer_channel ..
                                 ' toggle')
            end),

        awful.button({}, 4,
            function()
                awful.util.spawn('amixer set ' .. mixer_channel ..
                                 ' 2dB+ unmute')
            end),

        awful.button({}, 5,
            function()
                awful.util.spawn('amixer set ' .. mixer_channel ..
                                 ' 2dB- unmute')
            end)
    ))
    return myvolume
end

-- MPD
function mpd(mixer_channel, terminal)
    local mpdtable = {
        widget({ type = "textbox" }),
        widget({ type = "imagebox" }),
        widget({ type = "imagebox" }),
        widget({ type = "imagebox" }),
        widget({ type = "imagebox" })
    }

    mpdtable[1].text = " mpd: "

    mpdtable[2].image = image("/usr/share/icons/Tango/32x32/actions/" ..
                              "player_rew.png")
    mpdtable[3].image = image("/usr/share/icons/Tango/32x32/actions/" ..
                              "player_stop.png")
    mpdtable[4].image = image("/usr/share/icons/Tango/32x32/actions/" ..
                              "player_play.png")
    mpdtable[5].image = image("/usr/share/icons/Tango/32x32/actions/" ..
                              "player_fwd.png")

    local function buttons_for_mpdwidget(widg, cmd)
        widg:buttons(awful.util.table.join(
            awful.button({}, 1, function() awful.util.spawn(cmd) end),

            awful.button({}, 2,
                function()
                    awful.util.spawn(terminal .. ' -e ncmpcpp')
                end),

            awful.button({}, 3,
                function()
                    awful.util.spawn('amixer set ' .. mixer_channel ..
                                     ' toggle')
                end),

            awful.button({}, 4,
                function()
                    awful.util.spawn('amixer set ' .. mixer_channel ..
                                     ' 2dB+ unmute')
                end),

            awful.button({}, 5,
                function()
                    awful.util.spawn('amixer set ' .. mixer_channel ..
                                     ' 2dB- unmute')
                end)
        ))
    end
    buttons_for_mpdwidget(mpdtable[2], 'mpc prev')
    buttons_for_mpdwidget(mpdtable[3], 'mpc stop')
    buttons_for_mpdwidget(mpdtable[4], 'mpc toggle')
    buttons_for_mpdwidget(mpdtable[5], 'mpc next')
    return mpdtable
end

-- vim: set et :
