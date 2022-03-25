local gears     = require("gears")
local gstr      = require('gears.string')
local gio       = require('lgi').Gio
local wibox     = require('wibox')
local beautiful = require('beautiful')

local total_prev = 0
local idle_prev = 0
local hwmon_num = 0

local function updateload(wdg)
    gio.File.new_for_path('/proc/stat'):load_contents_async(nil,function(file,task,c)
        local content = file:load_contents_finish(task)
        if content then
            local lines = gstr.split(content, "\n")
            local cpustr = lines[1]
            local user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice =
                cpustr:match('(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)')

            local total = user + nice + system + idle + iowait + irq + softirq + steal
            local percentage = (1 - (idle - idle_prev) / (total - total_prev)) * 100
            wdg:add_value(percentage)

            total_prev = total
            idle_prev = idle

        end
    end)
end

local function updatetemp(textbox)
    gio.File.new_for_path('/sys/class/hwmon/hwmon' .. hwmon_num .. '/temp1_input'):load_contents_async(nil,function(file,task,c)
        local content = file:load_contents_finish(task)
        if content then
            local temp = string.gsub(content, "\n$", "")
            textbox:set_markup(temp/1000 .. '°')
        else
            textbox:set_markup("nv")
        end
    end)
end

local function get_hwmon()
    local hwmon_path = '/sys/class/hwmon/'
    local file_list = gio.File.new_for_path(hwmon_path):enumerate_children("standard::*", 0)
    if not file_list then return nil end
    for file in function() return file_list:next_file() end do
        local hwmon = file:get_display_name()
        gio.File.new_for_path(hwmon_path .. hwmon .. '/name'):load_contents_async(nil,function(file,task,c)
            local content = file:load_contents_finish(task)
            content = string.gsub(content, "\n", "")
            if content and content == 'coretemp' then
                hwmon_num = hwmon:match('(%d+)$')
            end
        end)
    end
end

local function new(args)
    local args = args or {}
    local cpugraph_widget = wibox.widget {
        max_value        = 100,
        color            = beautiful.fg_normal,
        background_color = beautiful.graph_bg,
        border_color     = beautiful.bg_normal,
        forced_width     = 50,
        step_width       = 2,
        step_spacing     = 1,
        widget           = wibox.widget.graph
    }

    local tempbox = wibox.widget.textbox()

    local cpuicon = wibox.widget.imagebox()
    cpuicon:set_image(beautiful.cpu)

    local tempicon = wibox.widget.imagebox()
    tempicon:set_image(beautiful.temp)

    local openbox  = wibox.widget.textbox()
    local sepbox   = wibox.widget.textbox()
    local closebox = wibox.widget.textbox()
    openbox:set_markup( shiny.fg(beautiful.highlight, "[ "))
    closebox:set_markup(shiny.fg(beautiful.highlight, " ]"))
    sepbox:set_markup(  shiny.fg(beautiful.highlight, " | "))

    --local cpu_widget = wibox.container.margin(wibox.container.mirror(cpugraph_widget, { horizontal = true }), 0, 0, 0, 2)
    local cpu_widget = cpugraph_widget

    get_hwmon()
    gears.timer {
        autostart = true,
        timeout   = 1,
        callback  = function()
            updateload(cpugraph_widget)
            updatetemp(tempbox)
        end
    }

    updateload(cpugraph_widget)
    updatetemp(tempbox)

    return {layout = wibox.layout.fixed.horizontal, openbox, cpuicon, cpu_widget, sepbox, tempicon, tempbox, closebox}
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
