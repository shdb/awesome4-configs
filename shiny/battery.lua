local gears     = require('gears')
local awful     = require('awful')
local gio       = require('lgi').Gio
local wibox     = require('wibox')
local naughty   = require('naughty')
local beautiful = require('beautiful')
local math      = require('math')
local capi      = { mouse = mouse }

local enery_full = 0
local percentage = 0
local status = ''
local infotext = nil
local batteryicon = wibox.widget.imagebox()

local function update(wdg)
    gio.File.new_for_path('/sys/class/power_supply/BAT0/energy_now'):load_contents_async(nil,function(file,task,c)
        local content = file:load_contents_finish(task)
        if content then
            local charge = string.gsub(content, "\n$", "")
            percentage = math.floor(charge / enery_full * 100)
            wdg:set_value(percentage)
            if percentage >= 30 then
                wdg:set_color(beautiful.fg_normal)
                batteryicon:set_image(beautiful.battery)
            elseif percentage < 15 then
                wdg:set_color(beautiful.fc_urgent)
                batteryicon:set_image(beautiful.battery_red)
            elseif percentage < 30 then
                wdg:set_color(beautiful.highlight)
                batteryicon:set_image(beautiful.battery_yellow)
            end
        end
    end)
    gio.File.new_for_path('/sys/class/power_supply/BAT0/status'):load_contents_async(nil,function(file,task,c)
        local content = file:load_contents_finish(task)
        if content then
            status = string.gsub(content, "\n$", "")
        end
    end)
end

local function get_full()
    gio.File.new_for_path('/sys/class/power_supply/BAT0/energy_full'):load_contents_async(nil,function(file,task,c)
        local content = file:load_contents_finish(task)
        if content then
            enery_full = string.gsub(content, "\n$", "")
        end
    end)
end

local function add_infotext()
    infotext = naughty.notify {
        text = tostring(percentage) .. '% ' .. status,
        timeout = 0,
        hover_timeout = 0.5,
        screen = capi.mouse.screen,
        icon = beautiful.battery,
    }
end

local function new(args)
    local args = args or {}
    get_full()
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

    batteryicon:set_image(beautiful.battery)

    local openbox  = wibox.widget.textbox()
    local closebox = wibox.widget.textbox()
    openbox:set_markup( shiny.fg(beautiful.highlight, " [ "))
    closebox:set_markup(shiny.fg(beautiful.highlight, " ] "))

    local timer = gears.timer {
        autostart = true,
        timeout   = 5,
        callback  = function()
            update(vbar)
        end
    }

    batteryicon:connect_signal("mouse::enter", function() add_infotext(0) end)
    batteryicon:connect_signal("mouse::leave", function() shiny.remove_notify(infotext) end)
    bar:connect_signal("mouse::enter", function() add_infotext(0) end)
    bar:connect_signal("mouse::leave", function() shiny.remove_notify(infotext) end)
    openbox:connect_signal("mouse::enter", function() add_infotext(0) end)
    openbox:connect_signal("mouse::leave", function() shiny.remove_notify(infotext) end)
    closebox:connect_signal("mouse::enter", function() add_infotext(0) end)
    closebox:connect_signal("mouse::leave", function() shiny.remove_notify(infotext) end)

    update(vbar)

    return {layout = wibox.layout.fixed.horizontal, openbox, batteryicon, bar, closebox}
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
