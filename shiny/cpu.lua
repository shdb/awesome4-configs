local gears     = require('gears')
local naughty   = require('naughty')
local awful     = require('awful')
local gstr      = require('gears.string')
local gio       = require('lgi').Gio
local wibox     = require('wibox')
local beautiful = require('beautiful')

local total_prev_cpu = {}
local idle_prev_cpu = {}
local percentage_cpu = {}
local hwmon_num = 0

local function updateload(wdg)
    gio.File.new_for_path('/proc/stat'):load_contents_async(nil,function(file,task,c)
        local content = file:load_contents_finish(task)
        if content then
            local lines = gstr.split(content, '\n')
            for i, cpustr in ipairs(lines) do
                local cpu, user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice =
                    cpustr:match('(cpu%d*)%s+(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)')

                if not cpu then break end
                local idle_prev = idle_prev_cpu[cpu] and idle_prev_cpu[cpu] or 0
                local total_prev = total_prev_cpu[cpu] and total_prev_cpu[cpu] or 0
                local total = user + nice + system + idle + iowait + irq + softirq + steal
                local percentage = (1 - (idle - idle_prev) / (total - total_prev)) * 100
                if cpu == 'cpu' then
                    wdg:add_value(percentage)
                end
                percentage_cpu[cpu] = percentage

                total_prev_cpu[cpu] = total
                idle_prev_cpu[cpu] = idle
            end
        end
    end)
end

local function updatetemp(textbox)
    gio.File.new_for_path('/sys/class/hwmon/hwmon' .. hwmon_num .. '/temp1_input'):load_contents_async(nil,function(file,task,c)
        local content = file:load_contents_finish(task)
        if content then
            local temp = string.gsub(content, '\n$', '')
            textbox:set_markup(temp/1000 .. '°')
        else
            textbox:set_markup('nv')
        end
    end)
end

local function get_hwmon()
    local hwmon_path = '/sys/class/hwmon/'
    local file_list = gio.File.new_for_path(hwmon_path):enumerate_children('standard::*', 0)
    if not file_list then return nil end
    for file in function() return file_list:next_file() end do
        local hwmon = file:get_display_name()
        gio.File.new_for_path(hwmon_path .. hwmon .. '/name'):load_contents_async(nil,function(file,task,c)
            local content = file:load_contents_finish(task)
            content = string.gsub(content, '\n', '')
            if content and content == 'coretemp' then
                hwmon_num = hwmon:match('(%d+)$')
                return hwmon_num
            end
        end)
    end
end

local function add_info(args)
    local cpuinfo = ''
    local perc_length = 0
    local cpu_perc = {}

    for i, percentage in pairs(percentage_cpu) do
        cpu_num = i:match('cpu(%d+)')
        if cpu_num then
            local perc = shiny.round_num(percentage, 1)
            cpu_perc[cpu_num + 1] = perc
            if perc_length < string.len(perc) then
                perc_length = string.len(perc)
            end
        end
    end

    for i, percentage in ipairs(cpu_perc) do
        cpuinfo = cpuinfo .. 'CPU' .. i - 1 .. ': ' .. shiny.lpaddto(shiny.round_num(percentage, 1), perc_length) .. '%\n'
    end
    cpuinfo = string.gsub(cpuinfo, '\n$', '')

    infotext = naughty.notify {
        text = cpuinfo,
        timeout = 0,
        hover_timeout = 0.5,
        screen = awful.screen.focused(),
        icon = beautiful.cpu,
    }
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
    openbox:set_markup( shiny.fg(beautiful.highlight, '[ '))
    closebox:set_markup(shiny.fg(beautiful.highlight, ' ]'))
    sepbox:set_markup(  shiny.fg(beautiful.highlight, ' | '))

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

    boxes = {openbox, cpuicon, cpu_widget, sepbox, tempicon, tempbox, closebox}
    for boxCount = 1, #boxes do
        boxes[boxCount]:connect_signal('mouse::enter', function() add_info() end)
        boxes[boxCount]:connect_signal('mouse::leave', function() shiny.remove_notify(infotext) end)
    end

    updateload(cpugraph_widget)
    updatetemp(tempbox)

    return {layout = wibox.layout.fixed.horizontal, openbox, cpuicon, cpu_widget, sepbox, tempicon, tempbox, closebox}
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
