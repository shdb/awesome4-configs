local gears     = require('gears')
local shiny     = require("shiny")
local wibox     = require("wibox")
local naughty   = require("naughty")
local awful     = require("awful")
local beautiful = require("beautiful")

local statusicon = wibox.widget.imagebox()
local vbar = wibox.widget.progressbar()
local bar = wibox.widget {
    {
        --color            = beautiful.fg_normal,
        color            = { type="linear", from = {0, 0}, to = {10, 0},
                             stops = { {0, beautiful.fg_normal},
                                       {0.5, beautiful.graph_center},
                                       {1.0, beautiful.graph_end}
                             }
                           },
        border_color     = beautiful.bg_normal,
        background_color = beautiful.graph_bg,
        ticks            = true,
        ticks_size       = 2,
        ticks_gap        = 1,
        max_value        = 150,
        widget           = vbar,
    },
    forced_width     = 4,
    direction        = 'east',
    layout           = wibox.container.rotate,
}

volume = {}
volume.mt = {}

function volume.update(sleeptime)
    cmd = 'pulsemixer --get-volume'
    if sleeptime ~= nil and sleeptime > 0 then cmd = 'sleep ' .. sleeptime .. '; ' .. cmd end
    awful.spawn.easy_async_with_shell(cmd, function(stat)
        local volume = stat:match("(%d?%d?%d) ")
        if volume then
            local volume = tonumber(volume)
            vbar:set_value(volume)
        end
    end)

    cmd = 'pulsemixer --get-mute'
    if sleeptime ~= nil and sleeptime > 0 then cmd = 'sleep ' .. sleeptime .. '; ' .. cmd end
    awful.spawn.easy_async_with_shell(cmd, function(stat)
        local state  = stat:match("(%d)")
        if state then
            if state == '1' then
                statusicon:set_image(beautiful.muted)
            else
                statusicon:set_image(beautiful.volume)
            end
        end
    end)
end

function volume.up()
    awful.spawn('pulsemixer --change-volume +2')
    volume.update(0.5)
end

function volume.down()
    awful.spawn('pulsemixer --change-volume -2')
    volume.update(0.5)
end

function volume.toggle()
    awful.spawn('pulsemixer --toggle-mute')
    volume.update(0.5)
end

function volume.new(o)
    setmetatable(o, volume.mt)
    local openbox  = wibox.widget.textbox()
    local closebox = wibox.widget.textbox()
    openbox:set_markup( shiny.fg(beautiful.highlight, "[ "))
    closebox:set_markup(shiny.fg(beautiful.highlight, " ]"))

    local timer = gears.timer {
        autostart = true,
        timeout   = 3,
        callback  = function()
            o.update()
        end
    }

    o.update()
    o.widget = {layout = wibox.layout.fixed.horizontal, openbox, statusicon, bar, closebox}
    return o
end

return setmetatable({}, { __call = function(_, ...) return volume:new(...) end })
