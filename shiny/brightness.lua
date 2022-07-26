local gears     = require('gears')
local awful     = require('awful')
local gio       = require('lgi').Gio
local wibox     = require('wibox')
local naughty   = require('naughty')
local beautiful = require('beautiful')
local math      = require('math')
local capi      = { mouse = mouse }

local maxsysfsbrightness = 0
local percentage = 0
local sysfspath = '/sys/class/backlight/intel_backlight/'
local status = ''
local infotext = nil
local brightnessicon = wibox.widget.imagebox()
local xrandr = nil
local percentagesteps = 5

local function check_backlight()
   local f = io.open(sysfspath .. 'brightness', 'r')
   if f ~= nil then
       io.close(f)
       xrandr = false
   else
       xrandr = true
   end
end

local function update(wdg)
    if xrandr == true then
        awful.spawn.easy_async_with_shell('xrandr --verbose | grep -i brightness | head -n1 | cut -f2 -d" "' , function(stat)
            percentage = stat * 100
            wdg:set_value(percentage)
        end)
    else
        gio.File.new_for_path(sysfspath .. 'brightness'):load_contents_async(nil,function(file,task,c)
            local content = file:load_contents_finish(task)
            if content then
                local brightness = string.gsub(content, "\n$", "")
                percentage = math.floor(brightness / maxsysfsbrightness * 100)
                wdg:set_value(percentage)
            end
        end)
    end
end

local function get_max()
    gio.File.new_for_path(sysfspath .. 'max_brightness'):load_contents_async(nil,function(file,task,c)
        local content = file:load_contents_finish(task)
        if content then
            maxsysfsbrightness = string.gsub(content, "\n$", "")
        end
    end)
end

local function adjust_brightness(amount, wdg)
    local newperc = percentage + amount
    if newperc > 100 then newperc = 100 end
    if newperc < percentagesteps then newperc = percentagesteps end
    newperc = math.floor((newperc + percentagesteps / 2) / percentagesteps) * percentagesteps

    if xrandr == true then
        local newxbrightness = newperc / 100
        awful.spawn.with_shell('for i in $(xrandr | grep " conn" | cut -f1 -d" "); do xrandr --output $i --brightness ' .. newxbrightness .. "; done")
    else
        local newsysfsbrightness = math.floor(maxsysfsbrightness / 100 * newperc + 0.5)
        gio.File.new_for_path(sysfspath .. 'brightness'):replace_contents_async(newsysfsbrightness,nil,nil,{},nil,nil,0)
    end

    wdg:set_value(newperc)
    naughty.notify {
        title = "Brightness",
        text = tostring(newperc),
        timeout = 2,
        screen = capi.mouse.screen,
    }
    percentage = newperc
end

local function new(args)
    local args = args or {}
    check_backlight()
    if not xrandr then get_max() end
    local vbar = wibox.widget.progressbar()
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
                awful.button({ }, 1, function() adjust_brightness(-5, vbar) end),
                awful.button({ }, 3, function() adjust_brightness( 5, vbar) end),
                awful.button({ }, 4, function() adjust_brightness( 1, vbar) end),
                awful.button({ }, 5, function() adjust_brightness(-1, vbar) end)
            )
        )
    end

    gears.timer {
        autostart = true,
        timeout   = 5,
        callback  = function()
            update(vbar)
        end
    }

    update(vbar)

    return {layout = wibox.layout.fixed.horizontal, openbox, brightnessicon, bar, closebox}
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
