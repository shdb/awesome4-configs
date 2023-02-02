-- some clients should keep their aspect ratio when resizing in floating mode

local client = client
local awful  = require("awful")
local gears  = require("gears")

local artable = {}
local keeparclients = {
    ["mpv"]      = true,
    ["Toolkit"]  = true,
}

client.disconnect_signal("request::geometry", awful.mouse.resize_handler)
client.connect_signal("request::geometry", function(c, context, hints)
    local t = c.screen.selected_tag
    local layout = t and t.layout or nil

    if context == "mouse.resize"
        and (c.floating or layout == awful.layout.suit.floating)
        and (keeparclients[c.class] or keeparclients[c.instance]) then

        hints = gears.table.clone(hints)

        if not artable[client] then
            local geo = c:geometry()
            artable[client] = geo.width / geo.height
        end

        hints.width  = gears.math.round(math.min(hints.width, artable[client] * hints.height))
        hints.height = gears.math.round(math.min(hints.height, hints.width / artable[client]))
    end

    return awful.mouse.resize_handler(c, context, hints)
end)
