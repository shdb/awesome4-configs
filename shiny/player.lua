local gears     = require('gears')
local shiny     = require("shiny")
local wibox     = require("wibox")
local naughty   = require("naughty")
local awful     = require("awful")
local beautiful = require("beautiful")
local math      = require('math')

player = {}
player.mt = {}
player.statusicon = wibox.widget.imagebox()
player.textbox = wibox.widget.textbox()
player.artist = ''
player.title = ''
player.length = ''
player.position = ''
player.separatortime = shiny.fg(beautiful.highlight, ' / ')
player.separatorartist = shiny.fg(beautiful.highlight, ' / ')
player.separatorposition = shiny.fg(beautiful.highlight, ' | ')
player.space = ' '

local sleeptime = 0.2


function player.formattime(time)
    time = tonumber(time)
    if not time or time == 0 then return '' end

    local hours = math.floor(time / 60^2)
    local minutes = string.format('%02d', math.floor(time % 60^2 / 60))
    local seconds = string.format('%02d', math.floor(time % 60 + 0.5))

    if hours > 0 then
        return hours .. ':' .. minutes .. ':' .. seconds
    else
        return minutes .. ':' .. seconds
    end
end

function player.escape(str)
	str = string.gsub(str, '&', '&amp;')
	str = string.gsub(str, '<', '&lt;')
	str = string.gsub(str, '>', '&gt;')
	str = string.gsub(str, "'", '&apos;')
	str = string.gsub(str, '"', '&quot;')

	return str
end

function player.updateinfo()
    player.separatorartist = (player.artist == '' or player.title == '') and '' or shiny.fg(beautiful.highlight, ' / ')
    player.separatortime = (player.length == '' or player.position == '') and '' or shiny.fg(beautiful.highlight, ' / ')
    player.separatorposition = (player.length == '' or player.position == '') and '' or shiny.fg(beautiful.highlight, ' | ')
    player.space = (player.length == '' and player.position == '' and player.artist == '' and player.title == '') and '' or ' '
    player.textbox:set_markup(player.space .. player.escape(player.artist) .. player.separatorartist .. player.escape(player.title) .. player.separatorposition
        .. player.formattime(player.position) .. player.separatortime .. player.formattime(player.length))
end

function player.updatestatus(stat)
    if stat == nil or stat == '' then
        player.statusicon:set_image(beautiful.player_stop)
    elseif stat:match('Paused') then
        player.statusicon:set_image(beautiful.player_pause)
    elseif stat:match('Playing') then
        player.statusicon:set_image(beautiful.player_play)
    else
        player.statusicon:set_image(beautiful.player_stop)
    end
end

function player.update(sleeptime)
    cmd = 'playerctl metadata -f "__status:{{status}} __artist:{{artist}} __title:{{title}} __position:{{position}} __length:{{mpris:length}}"'
    if sleeptime ~= nil and sleeptime > 0 then cmd = 'sleep ' .. sleeptime .. '; ' .. cmd end
    awful.spawn.easy_async_with_shell(cmd, function(stat)
        if stat == nil or stat == '' then
            player.artist = ''
            player.title = ''
            player.length = ''
            return player.textbox:set_markup('')
        else
            local status = stat:match('__status:(.+) __artist') or ''
            player.updatestatus(status)

            local artist = stat:match('.*__artist:(.+) __title') or ''
            artist = artist:gsub('-%sTopic$', '')
            player.artist = artist:gsub('%s+$', '')

            player.title  = stat:match('__title:(.+) __position') or ''

            local position = stat:match('__position:(.+) __length') or ''
            if tonumber(position) and tonumber(position) > 1000 then
                player.position = tonumber(position) / 10^6
            else
                player.position = ''
            end

            local length = stat:match('__length:(.+)$') or ''
            if tonumber(length) and tonumber(length) > 1000 then
                player.length = tonumber(length) / 10^6
            else
                player.length = ''
            end
        end
        player.updateinfo()
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

function player.seekfw(amount)
    amount = amount or 5
    awful.spawn('playerctl position ' .. amount .. '+')
    player.update(sleeptime)
end

function player.seekbw(amount)
    amount = amount or 5
    awful.spawn('playerctl position ' .. amount .. '-')
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
                awful.button({ }, 2, function() player.previous() end),
                awful.button({ }, 4, function() player.seekbw(1) end),
                awful.button({ }, 5, function() player.seekfw(1) end)
            )
        )
    end

    gears.timer {
        autostart = true,
        timeout   = 1,
        callback  = function()
            o.update()
        end
    }

    o.update()
    o.widget = {layout = wibox.layout.fixed.horizontal, openbox, player.statusicon, player.textbox, closebox}
    return o
end

return setmetatable({}, { __call = function(_, ...) return player:new(...) end })
