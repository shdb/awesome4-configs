local gears     = require('gears')
local awful     = require('awful')
local gio       = require('lgi').Gio
local wibox     = require('wibox')
local naughty   = require('naughty')
local beautiful = require('beautiful')
local math      = require('math')

local maxsysfsbrightness = 0
local percentage = 0
local sysfspath = ''
local status = ''
local infotext = nil
local vbar = wibox.widget.progressbar()
local brightnessicon = wibox.widget.imagebox()
local xrandr = nil

brightness = {}
brightness.mt = {}

function brightness.check_backlight()
    local blbasepath = '/sys/class/backlight/'
    local bllist = gio.File.new_for_path(blbasepath):enumerate_children("standard::*", 0)
    if not bllist then
        xrandr = true
        return nil
    end
    for file in function() return bllist:next_file() end do
        local bl = file:get_display_name()
        xrandr = false
        sysfspath = blbasepath .. bl .. '/'
        return bl
    end
    xrandr = true
    return nil
end

function brightness.update()
    if xrandr == true then
        awful.spawn.easy_async_with_shell('xrandr --current --verbose | grep -i brightness | head -n1 | cut -f2 -d" "' , function(stat)
            percentage = stat * 100
            vbar:set_value(percentage)
        end)
    else
        gio.File.new_for_path(sysfspath .. 'brightness'):load_contents_async(nil,function(file,task,c)
            local content = file:load_contents_finish(task)
            if content then
                local brightness = string.gsub(content, "\n$", "")
                percentage = math.floor(brightness / maxsysfsbrightness * 100)
                vbar:set_value(percentage)
            end
        end)
    end
end

function brightness.get_max()
    gio.File.new_for_path(sysfspath .. 'max_brightness'):load_contents_async(nil,function(file,task,c)
        local content = file:load_contents_finish(task)
        if content then
            maxsysfsbrightness = string.gsub(content, "\n$", "")
        end
    end)
end

function brightness.adjust(amount)
    local newperc = percentage + amount
    local amountabs = math.abs(amount)
    if newperc > 100 then newperc = 100 end
    if newperc < amountabs then newperc = amountabs end
    newperc = math.floor((newperc + amountabs / 2) / amountabs) * amountabs

    if xrandr == true then
        local newxbrightness = newperc / 100
        awful.spawn.with_shell('for i in $(xrandr --current | grep " conn" | cut -f1 -d" "); do xrandr --current --output $i --brightness ' .. newxbrightness .. "; done")
    else
        local newsysfsbrightness = math.floor(maxsysfsbrightness / 100 * newperc + 0.5)
        gio.File.new_for_path(sysfspath .. 'brightness'):replace_contents_async(newsysfsbrightness,nil,nil,{},nil,nil,0)
    end

    vbar:set_value(newperc)
    naughty.notify {
        title = "Brightness",
        text = tostring(newperc),
        timeout = 2,
        screen = awful.screen.focused(),
    }
    percentage = newperc
end

function brightness.new(o)
    setmetatable(o, brightness.mt)
    o.check_backlight()
    if not xrandr then o.get_max() end
    local bar = wibox.widget {
        {
            color            = beautiful.fg_normal,
            border_color     = beautiful.bg_normal,
            background_color = beautiful.graph_bg,
            ticks            = true,
            ticks_size       = 2,
            ticks_gap        = 1,
            max_value        = 100,
            widget           = vbar,
        },
        forced_width     = 4,
        direction        = 'east',
        layout           = wibox.container.rotate,
    }

    brightnessicon:set_image(beautiful.brightness)

    local openbox  = wibox.widget.textbox()
    local closebox = wibox.widget.textbox()
    openbox:set_markup( shiny.fg(beautiful.highlight, "[ "))
    closebox:set_markup(shiny.fg(beautiful.highlight, " ]"))

    local widgetboxes = {openbox, brightnessicon, bar, closebox}
    for i, widgetbox in ipairs(widgetboxes) do
        widgetbox:buttons(
            gears.table.join(
                awful.button({ }, 1, function() o.adjust(-5) end),
                awful.button({ }, 3, function() o.adjust( 5) end),
                awful.button({ }, 4, function() o.adjust( 1) end),
                awful.button({ }, 5, function() o.adjust(-1) end)
            )
        )
    end

    gears.timer {
        autostart = true,
        timeout   = 5,
        callback  = function()
            o.update()
        end
    }

    o.update()

    o.widget = {layout = wibox.layout.fixed.horizontal, openbox, brightnessicon, bar, closebox}
    return o
end

return setmetatable({}, { __call = function(_, ...) return brightness:new(...) end })
