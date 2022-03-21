local gears     = require("gears")
local naughty   = require("naughty")
local awful     = require("awful")
local gio       = require('lgi').Gio
local wibox     = require('wibox')
local beautiful = require('beautiful')
local capi      = { mouse = mouse }

local infotext = nil
local total = nil
local available = nil

local function update(wdg)
    gio.File.new_for_path('/proc/meminfo'):load_contents_async(nil,function(file,task,c)
        local content = file:load_contents_finish(task)
        if content then
            local lines = gears.string.split(content, "\n")
            local memtot = lines[1]
            local memav  = lines[3]
            total = memtot:match('(%d+)')
            available = memav:match('(%d+)')

            local percentage = (1 - (available / total)) * 100
            wdg:set_value(percentage)

        end
    end)
end

local function add_info(args)
    local memused = total - available
    infotext = naughty.notify {
        text = tonumber(string.format("%.2f", memused / 1024^2)) .. '/' .. tonumber(string.format("%.2f", total / 1024^2)) .. ' GB',
        timeout = 0,
        hover_timeout = 0.5,
        screen = capi.mouse.screen,
        icon = beautiful.mem,
    }

end

local function new(args)
    local args = args or {}
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
            max_value        = 100,
            widget           = vbar,
        },
        forced_width     = 4,
        direction        = 'east',
        layout           = wibox.container.rotate,
    }

    local memicon = wibox.widget.imagebox()
    memicon:set_image(beautiful.mem)

    local openbox  = wibox.widget.textbox()
    local closebox = wibox.widget.textbox()
    openbox:set_markup( shiny.fg(beautiful.highlight, "[ "))
    closebox:set_markup(shiny.fg(beautiful.highlight, " ]"))

    local timer = gears.timer {
        autostart = true,
        timeout   = 1,
        callback  = function()
            update(vbar)
        end
    }

    boxes = {openbox, memicon, vbar, closebox}
    for boxCount = 1, #boxes do
        boxes[boxCount]:connect_signal("mouse::enter", function() add_info() end)
        boxes[boxCount]:connect_signal("mouse::leave", function() shiny.remove_notify(infotext) end)
    end

    update(vbar)

    return {layout = wibox.layout.fixed.horizontal, openbox, memicon, bar, closebox}
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
