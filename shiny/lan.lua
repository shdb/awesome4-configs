local gears     = require("gears")
local gio       = require('lgi').Gio
local awful     = require("awful")
local beautiful = require("beautiful")
local shiny     = require("shiny")
local wibox     = require("wibox")

local tonumber = tonumber
local setmetatable = setmetatable
local string = string
local math = { floor = math.floor }
local os = { time = os.time }
local widget, button, mouse, table, tostring, pairs
    = widget, button, mouse, table, tostring, pairs

-- display network statistics
local net = { mt = {} }


local interface
local icon     = wibox.widget.imagebox()
local infobox  = wibox.widget.textbox()
local openbox  = wibox.widget.textbox()
local closebox = wibox.widget.textbox()
openbox:set_markup( shiny.fg(beautiful.highlight, "[ "))
closebox:set_markup(shiny.fg(beautiful.highlight, " ] "))

local function create_graph()
    local graph = wibox.widget {
        color = beautiful.fg_normal,
        background_color = beautiful.graph_bg,
        border_color = beautiful.bg_normal,
        forced_width = 50,
        step_width = 2,
        step_spacing = 1,
        scale = true,
        widget = wibox.widget.graph,
    }
    return graph
end

local nets = {}

local function process_net_data(data, interface)
    local args = {}
    local lines = gears.string.split(data, "\n")
    for i, l in ipairs(lines) do
        line = shiny.splitbywhitespace(l)

        if line[1] ~= nil then
            local p = line[1]:find(':')
            if p ~= nil then
                local name = line[1]:sub(0,p-1)
                if name == interface then
                    line[1] = line[1]:sub(p+1)

                    if tonumber(line[1]) == nil then
                        line[1] = line[2]
                        line[9] = line[10]
                    end

                    if nets[name] == nil then
                        nets[name] = {}

                        args['down_kb'] = 0
                        args['up_kb']   = 0

                        nets[name].time = os.time()
                    else
                        local interval = os.time()-nets[name].time
                        interval = interval > 0 and interval or 1
                        nets[name].time = os.time()

                        down = (line[1] - nets[name][1]) / interval
                        up   = (line[9] - nets[name][2]) / interval

                        args['down_kb'] = shiny.round_num(down/1024, 1, 1)
                        args['up_kb']   = shiny.round_num(up/1024, 1, 1)
                    end

                    nets[name][1] = line[1]
                    nets[name][2] = line[9]
                end
            end
        end
    end
    return args
end

local padding = 0
local paddu = 0
local function padd(text)
    local text = tostring(text)
    if text:len() >= padding then
        padding = text:len()
        paddu = 0
    else
        paddu = paddu + 1
        if paddu == 30 then
            paddu = 0
            padding = padding - 1
        end
    end
    while text:len() < padding do
        text = " " .. text
    end
    return text
end

local function update(gd, gu)
    gio.File.new_for_path('/proc/net/dev'):load_contents_async(nil,function(file,task,c)
        local content = file:load_contents_finish(task)
        if content then
            local data = process_net_data(content, interface)
            gd:add_value(data['down_kb'])
            gu:add_value(data['up_kb'])
            text = padd(data['down_kb'])
                .. shiny.fg(beautiful.highlight, " / ")
                .. padd(data['up_kb'])
            infobox:set_markup(text)
        end
    end)
end

function getInterface(args)
    cmd = 'ip -o -4 route show to default | grep -v tun | head -1 | cut -f5 -d" "'
    awful.spawn.easy_async_with_shell(cmd, function(stat)
        if stat then
            interface = string.gsub(stat, "\n", "")
        end
    end)
end

function new(args)
    local icon = wibox.widget.imagebox()
    icon:set_image(beautiful.network)

    local graph_down = create_graph()
    local graph_up   = create_graph()

    getInterface()

    local timer = gears.timer {
        autostart = true,
        timeout   = 1,
        callback  = function()
            getInterface()
            update(graph_down, graph_up)
        end
    }
    return { layout = wibox.layout.fixed.horizontal, openbox, icon, infobox, graph_down, graph_up, closebox }

end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
