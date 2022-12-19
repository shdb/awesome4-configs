local gears     = require('gears')
local shiny     = require("shiny")
local wibox     = require('wibox')
local naughty   = require('naughty')
local awful     = require('awful')
local beautiful = require('beautiful')

local statusicon = wibox.widget.imagebox()
local vbar = wibox.widget.progressbar()
local bar = wibox.widget {
    {
        --color            = beautiful.fg_normal,
        color = {
            type = 'linear',
            from = {0, 0},
            to = {10, 0},
            stops = {
                { 0,   beautiful.fg_normal },
                { 0.5, beautiful.graph_center },
                { 1.0, beautiful.graph_end }
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
    forced_width = 4,
    direction    = 'east',
    layout       = wibox.container.rotate,
}

volume = {}
volume.mt = {}

function volume.update(sleeptime)
    cmd = 'wpctl get-volume @DEFAULT_AUDIO_SINK@'
    if sleeptime ~= nil and sleeptime > 0 then cmd = 'sleep ' .. sleeptime .. '; ' .. cmd end
    awful.spawn.easy_async_with_shell(cmd, function(stat)
        local volume = stat:match("(%d.%d%d)")
        if volume then
            local volume = tonumber(volume) * 100
            vbar:set_value(volume)
        end

        local mute = stat:match("(MUTED)")
        if mute and mute == 'MUTED' then
            statusicon:set_image(beautiful.muted)
        else
            statusicon:set_image(beautiful.volume)
        end
    end)
end

function volume.up(amount)
    amount = amount and amount / 100 or 0.02
    awful.spawn('wpctl set-volume @DEFAULT_AUDIO_SINK@ ' .. amount .. '+')
    volume.update(0.2)
end

function volume.down(amount)
    amount = amount and amount / 100 or 0.02
    awful.spawn('wpctl set-volume @DEFAULT_AUDIO_SINK@ ' .. amount .. '-')
    volume.update(0.2)
end

function volume.toggle()
    awful.spawn('wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle')
    volume.update(0.2)
end

function volume.new(o)
    setmetatable(o, volume.mt)
    local openbox  = wibox.widget.textbox()
    local closebox = wibox.widget.textbox()
    openbox:set_markup( shiny.fg(beautiful.highlight, "[ "))
    closebox:set_markup(shiny.fg(beautiful.highlight, " ]"))

    local widgetboxes = {openbox, statusicon, bar, closebox}
    for i, widgetbox in ipairs(widgetboxes) do
        widgetbox:buttons(
            gears.table.join(
                awful.button({ }, 1, function() o.toggle() end),
                awful.button({ }, 4, function() o.up(1) end),
                awful.button({ }, 5, function() o.down(1) end)
            )
        )
    end

    gears.timer {
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
