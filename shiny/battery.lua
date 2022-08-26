local gears     = require('gears')
local awful     = require('awful')
local gio       = require('lgi').Gio
local wibox     = require('wibox')
local naughty   = require('naughty')
local beautiful = require('beautiful')
local math      = require('math')

local data = {}
data['energy_full'] = 0
data['energy']      = 0
data['power']       = 0
data['status']      = ''
local percentage    = 0
local infotext      = nil
local sysfspath     = '/sys/class/power_supply/BAT0/'
local batteryicon   = wibox.widget.imagebox()

local function have_battery()
   local f = io.open(sysfspath .. 'energy_now', 'r')
   if f ~= nil then
       io.close(f)
       return true
   else
       return false
   end
end

local function get_file_content(file, var)
    gio.File.new_for_path(file):load_contents_async(nil,function(file,task,c)
        local content = file:load_contents_finish(task)
        if content then
            data[var] = string.gsub(content, '\n$', '')
        end
    end)
end

local function update(wdg)
    gio.File.new_for_path(sysfspath .. 'energy_now'):load_contents_async(nil,function(file,task,c)
        local content = file:load_contents_finish(task)
        if content then
            local charge = string.gsub(content, '\n$', '')
            percentage = math.floor(charge / data['energy_full'] * 100)
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

    get_file_content(sysfspath .. 'power_now',  'power')
    get_file_content(sysfspath .. 'energy_now', 'energy')
    get_file_content(sysfspath .. 'status',     'status')
end

local function add_info()
    local remaining_text = ''
    local remaining = 0

    if data['status'] == 'Discharging' then
        remaining = (data['energy'] * 3600) / data['power'] / 60
    elseif data['status'] == 'Charging' then
        remaining = 3600 * (data['energy_full'] - data['energy']) / data['power'] / 60
    end

    if remaining ~= 0 then
        local hours
        local minutes
        remaining_text = '\nremaining: '
        if remaining > 60 then
            hours = math.floor(remaining / 60)
            minutes = string.format('%02d', math.floor(remaining % 60 + 0.5))
            remaining_text = remaining_text  .. shiny.fg(beautiful.highlight, hours .. ':' .. minutes)
        else
            minutes = string.format('%02d', math.floor(remaining + 0.5))
            remaining_text = remaining_text .. shiny.fg(beautiful.highlight, minutes)
        end
    end

    infotext = naughty.notify {
        text = data['status'] .. ': ' .. shiny.fg(beautiful.highlight, tostring(percentage) .. '%') .. remaining_text,
        timeout = 0,
        hover_timeout = 0.5,
        screen = awful.screen.focused(),
        icon = beautiful.battery,
    }
end

local function new(args)
    local args = args or {}
    local openbox  = wibox.widget.textbox()
    local closebox = wibox.widget.textbox()

    if not have_battery() then
        openbox:set_markup('')
        return {layout = wibox.layout.fixed.horizontal, openbox}
    end

    get_file_content(sysfspath .. 'energy_full', 'energy_full')
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
        forced_width = 4,
        direction    = 'east',
        layout       = wibox.container.rotate,
    }

    batteryicon:set_image(beautiful.battery)

    openbox:set_markup( shiny.fg(beautiful.highlight, '[ '))
    closebox:set_markup(shiny.fg(beautiful.highlight, ' ]'))

    gears.timer {
        autostart = true,
        timeout   = 5,
        callback  = function()
            update(vbar)
        end
    }

    boxes = {batteryicon, bar, openbox, closebox}
    for boxCount = 1, #boxes do
        boxes[boxCount]:connect_signal('mouse::enter', function() add_info() end)
        boxes[boxCount]:connect_signal('mouse::leave', function() shiny.remove_notify(infotext) end)
    end

    update(vbar)

    return {layout = wibox.layout.fixed.horizontal, openbox, batteryicon, bar, closebox}
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
