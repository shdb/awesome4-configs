local lgi       = require("lgi")
local gears     = require('gears')
local shiny     = require("shiny")
local wibox     = require("wibox")
local naughty   = require("naughty")
local awful     = require("awful")
local beautiful = require("beautiful")
local math      = require('math')

playerctl = { mt = {} }


function playerctl:formattime(time)
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

function playerctl:init_player(name)
    local player = self.Playerctl.Player.new_from_name(name)
    self.manager:manage_player(player)
    player.on_metadata = function(player, metadata)
        self:metadata_cb(player, metadata)
    end

    player.on_playback_status = function(player, status)
        self:status_cb(player, status)
    end

    player.on_seeked = function(player, position)
        self:update(player, true)
    end

    player.on_exit = function(player)
        self.textbox:set_markup('')
        self.active = nil
        gears.timer.delayed_call(function()
            self:init_data()
        end)
    end

    self.active = player
    self:init_data(player)
end

function playerctl:metadata_cb(player, metadata)
    local data = metadata.value
    self.title = data["xesam:title"] or ""
    self.artist = data["xesam:artist"][1] or ""
    self.length = (data["mpris:length"] or 0) / 10^6
    self:update(player)
end

function playerctl:status_cb(player, status)
    self.status = status
    self:update(player, true)
end

function playerctl:player_exists(player)
    for _, lplayer in ipairs(self.manager.players) do
        if lplayer == player then return true end
    end
    return false
end

function playerctl:init_data(player)
    if not player then
        if not (self.active or self.manager.players[1]) then
            self.textbox:set_markup()
            return
        else
            player = self.active or self.manager.players[1]
        end
    end

    if not playerctl:player_exists(player) then return end

    self.status = player.playback_status
    self.artist = player:get_artist() or ''
    self.title = player:get_title() or ''
    self.length = (player.metadata.value["mpris:length"] or 0) / 10^6

    self:update(player)
end

function playerctl:update(player, checkactive)
    if checkactive and player and self.active ~= player then
        self.active = player
        self:init_data(player)
    end
    if not player then
        if not (self.active or self.manager.players[1]) then
            self.textbox:set_markup()
            return
        else
            player = self.active or self.manager.players[1]
        end
    end

    if not playerctl:player_exists(player) then return end

    local artist = gears.string.xml_escape(self.artist)
    local title = gears.string.xml_escape(self.title)
    local position = (player:get_position() or 0) / 10^6
    if self.length == 0 then
        self.length = (player.metadata.value["mpris:length"] or 0) / 10^6
    end
    local length = self.length

    local separatorartist = (artist == '' or title == '') and '' or shiny.fg(beautiful.highlight, ' / ')
    local separatortime = (length == 0 or position == 0) and '' or shiny.fg(beautiful.highlight, ' / ')
    local separatorposition = (length == 0 or position == 0) and '' or shiny.fg(beautiful.highlight, ' | ')
    local space = (length == 0 and position == 0 and artist == '' and title == '') and '' or ' '

    if self.status == nil or self.status == '' then
        self.statusicon:set_image(beautiful.player_stop)
    elseif self.status == 'PAUSED' then
        self.statusicon:set_image(beautiful.player_pause)
    elseif self.status == 'PLAYING' then
        self.statusicon:set_image(beautiful.player_play)
    else
        self.statusicon:set_image(beautiful.player_stop)
    end

    self.textbox:set_markup(space .. artist .. separatorartist .. title .. separatorposition
        .. self:formattime(position) .. separatortime .. self:formattime(length))
end

function playerctl:playpause(player)
    player = player or self.active or self.manager.players[1]
    if not player then return end
    player:play_pause()
end

function playerctl:play(player)
    player = player or self.active or self.manager.players[1]
    if not player then return end
    player:play()
end

function playerctl:pause(player)
    player = player or self.active or self.manager.players[1]
    if not player then return end
    player:pause()
end

function playerctl:next(player)
    player = player or self.active or self.manager.players[1]
    if not player then return end
    player:next()
end

function playerctl:previous(player)
    player = player or self.active or self.manager.players[1]
    if not player then return end
    player:previous()
end

function playerctl:seekfw(amount, player)
    amount = amount or 5
    player = player or self.active or self.manager.players[1]
    if not player then return end
    player:seek(amount * 10^6)
end

function playerctl:seekbw(amount, player)
    amount = amount or 5
    player = player or self.active or self.manager.players[1]
    if not player then return end
    player:seek('-' .. amount * 10^6)
end

function playerctl:stop(player)
    player = player or self.active or self.manager.players[1]
    if not player then return end
    player:stop()
end

function playerctl:new()
    setmetatable(self, self.mt)
    self.statusicon = wibox.widget.imagebox(beautiful.player_stop)
    self.textbox = wibox.widget.textbox()
    self.Playerctl = lgi.Playerctl
    self.manager = self.Playerctl.PlayerManager()
    self.active = nil
    self.artist = ''
    self.title = ''
    self.length = 0
    self.position = 0

    local _self = self
    -- manage existing players on startup
    for _, name in ipairs(self.manager.player_names) do
        _self:init_player(name)
    end

    -- manage new players
    function self.manager:on_name_appeared(name)
        _self:init_player(name)
    end

    gears.timer {
        autostart = true,
        timeout   = 1,
        callback  = function()
            self:update()
        end
    }

    local openbox  = wibox.widget.textbox()
    local closebox = wibox.widget.textbox()
    openbox:set_markup( shiny.fg(beautiful.highlight, "[ "))
    closebox:set_markup(shiny.fg(beautiful.highlight, " ]"))

    local widgetboxes = {openbox, self.textbox, closebox}
    for i, widgetbox in ipairs(widgetboxes) do
        widgetbox:buttons(
            gears.table.join(
                awful.button({ }, 1, function() self:playpause() end),
                awful.button({ }, 3, function() self:next() end),
                awful.button({ }, 2, function() self:previous() end),
                awful.button({ }, 4, function() self:seekbw(1) end),
                awful.button({ }, 5, function() self:seekfw(1) end)
            )
        )
    end


    self.widget = {layout = wibox.layout.fixed.horizontal, openbox, self.statusicon, self.textbox, closebox}
    return self
end

return setmetatable({}, { __call = function(_, ...) return playerctl:new(...) end })
