local shiny     = require("shiny")
local wibox     = require("wibox")
local naughty   = require("naughty")
local awful     = require("awful")
local gears     = require("gears")
local beautiful = require("beautiful")
local capi      = { mouse = mouse }

local calendar   = nil
local cal_offset = 0

local function add_calendar(inc_offset)
    cal_offset = cal_offset + inc_offset

    local datespec = os.date("*t")
    datespec = datespec.year * 12 + datespec.month - 1 + cal_offset
    datespec = (datespec % 12 + 1) .. " " .. math.floor(datespec / 12)

    awful.spawn.easy_async_with_shell("cal -mw " .. datespec, function(cal)
        if cal_offset == 0 then -- this month, highlight day and month
            cal = string.gsub(cal, "(%d +)(" .. tonumber(os.date("%d")) .. "%s)", "%1" .. shiny.bold(shiny.fg(beautiful.highlight, "%2")))
            cal = string.gsub(cal, "^(%s+%w+%s+%d+)", shiny.bold(shiny.fg(beautiful.highlight, "%1")))
        end

        local ctext = string.format('<span font_desc="%s">%s</span>', "monospace", cal)
        if inc_offset ~= 0 then
            naughty.replace_text(calendar, nil, ctext)
        else
            calendar = naughty.notify {
                text = ctext,
                timeout = 0,
                hover_timeout = 0.5,
                screen = capi.mouse.screen,
            }
        end
    end)
end

local function new(args)
    local mytextclock = wibox.widget.textclock("%a %d.%m " .. shiny.fg(beautiful.highlight, "|") .. " %H:%M:%S")
    mytextclock:set_refresh(1)
    mytextclock:connect_signal("mouse::enter", function() add_calendar(0) end)
    mytextclock:connect_signal("mouse::leave", function() shiny.remove_notify(calendar); cal_offset = 0 end)

    mytextclock:buttons(
        gears.table.join(
            awful.button({ }, 1, function() add_calendar(-1) end),
            awful.button({ }, 3, function() add_calendar( 1) end)
        )
    )


    local openbox  = wibox.widget.textbox()
    local closebox = wibox.widget.textbox()
    openbox:set_markup( shiny.fg(beautiful.highlight, " [ "))
    closebox:set_markup(shiny.fg(beautiful.highlight, " ] "))

    return {layout = wibox.layout.fixed.horizontal, openbox, mytextclock, closebox}
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
