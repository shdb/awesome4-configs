local shiny     = require("shiny")
local gears     = require("gears")
local beautiful = require("beautiful")
local wibox     = require("wibox")        

local setmetatable = setmetatable
local tonumber = tonumber
local client, screen, string, mouse = client, screen, string, mouse

-- display active scren

local infobox = {}
for s = 1, screen.count() do
    infobox[s] = wibox.widget.textbox()
end

local function update()
    if screen.count() == 1 then return end
    for s = 1, screen.count() do
        local ltext = ""
    
        for ls = 1, screen.count() do
            if mouse.screen.index == s and mouse.screen.index == ls then
                ltext = ltext .. shiny.fg(beautiful.highlight, s) .. " "
            elseif mouse.screen.index == ls then
                ltext = ltext .. shiny.fg(beautiful.fg_focus, ls) .. " "
            else
                ltext = ltext .. ls .. " "
            end
        end

        infobox[s]:set_markup(
                shiny.fg(beautiful.highlight, "[ ")
                .. ltext
                .. shiny.fg(beautiful.highlight, "]")
            )
    end
end

if screen.count() > 1 then
	local timer = gears.timer {
		autostart = true,
		timeout   = 1,
		callback  = function()
			update()
		end
	}
    client.connect_signal("focus", function(c)
        update(c)
    end)
    client.connect_signal("unfocus", function(c)
        update(c)
    end)
end

function new(lsc)
    return infobox[lsc]
end

--return setmetatable(screen_mod, screen_mod.mt)
return setmetatable({}, { __call = function(_, ...) return new(...) end })
