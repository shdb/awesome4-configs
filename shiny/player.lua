local gears     = require('gears')
local shiny     = require("shiny")
local wibox     = require("wibox")
local naughty   = require("naughty")
local awful     = require("awful")
local beautiful = require("beautiful")

player = {}
player.mt = {}
player.statusicon = wibox.widget.imagebox()
player.textbox = wibox.widget.textbox()

local sleeptime = 0.2


function player.update(sleeptime)
    cmd = 'playerctl status'
    if sleeptime ~= nil and sleeptime > 0 then cmd = 'sleep ' .. sleeptime .. '; ' .. cmd end
    awful.spawn.easy_async_with_shell(cmd, function(stat)
        if stat == nil or stat == '' then
            player.statusicon:set_image(beautiful.player_stop)
        elseif stat:match('Paused') then
            player.statusicon:set_image(beautiful.player_pause)
        elseif stat:match('Playing') then
            player.statusicon:set_image(beautiful.player_play)
        else
            player.statusicon:set_image(beautiful.player_stop)
        end
    end)

    cmd = 'playerctl metadata'
    if sleeptime ~= nil and sleeptime > 0 then cmd = 'sleep ' .. sleeptime .. '; ' .. cmd end
    awful.spawn.easy_async_with_shell(cmd, function(stat)
        if stat == nil or stat == '' then
            player.textbox:set_markup('')
        else
            --local lines = gears.string.split(stat, "\n")
            local artist = stat:match('artist%s+([^\n]+)\n') or ''
            local title  = stat:match('title%s+([^\n]+)\n') or ''
            artist = artist:gsub('-%sTopic\n', '')
            artist = artist:gsub('%s+\n', '')
            local separator = (artist == '' or title == '') and '' or shiny.fg(beautiful.highlight, ' / ')
            player.textbox:set_markup(' ' .. artist .. separator .. title)
        end
    end)
end

function player.playpause()
    awful.spawn('playerctl play-pause')
    player.update(sleeptime)
end

function player.play()
    awful.spawn('playerctl play')
    player.update(sleeptime)
end

function player.pause()
    awful.spawn('playerctl pause')
    player.update(sleeptime)
end

function player.next()
    awful.spawn('playerctl next')
    player.update(sleeptime)
end

function player.previous()
    awful.spawn('playerctl previous')
    player.update(sleeptime)
end

function player.seekfw()
    awful.spawn('playerctl position 5+')
    player.update(sleeptime)
end

function player.seekbw()
    awful.spawn('playerctl position 5-')
    player.update(sleeptime)
end

function player.stop()
    awful.spawn('playerctl stop')
    player.update(sleeptime)
end

function player.new(o)
    setmetatable(o, player.mt)
    local openbox  = wibox.widget.textbox()
    local closebox = wibox.widget.textbox()
    openbox:set_markup( shiny.fg(beautiful.highlight, "[ "))
    closebox:set_markup(shiny.fg(beautiful.highlight, " ]"))

    local widgetboxes = {openbox, player.textbox, closebox}
    for i, widgetbox in ipairs(widgetboxes) do
        widgetbox:buttons(
            gears.table.join(
                awful.button({ }, 1, function() player.playpause() end),
                awful.button({ }, 3, function() player.next() end),
                awful.button({ }, 2, function() player.previous() end)
            )
        )
    end

    gears.timer {
        autostart = true,
        timeout   = 5,
        callback  = function()
            o.update()
        end
    }

    o.update()
    o.widget = {layout = wibox.layout.fixed.horizontal, openbox, player.statusicon, player.textbox, closebox}
    return o
end

return setmetatable({}, { __call = function(_, ...) return player:new(...) end })
