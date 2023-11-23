local lgi       = require("lgi")
local gears     = require('gears')
local shiny     = require("shiny")
local wibox     = require("wibox")
local naughty   = require("naughty")
local awful     = require("awful")
local beautiful = require("beautiful")
local math      = require('math')

local playerctl = { mt = {} }


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
        self.active = nil
        self.players[player] = nil
        if self:playercount() == 0 then self.textbox:set_markup('') end
        gears.timer.delayed_call(function()
            self:init_data()
        end)
    end

    self.active = player
    self:init_data(player)
end

function playerctl:metadata_cb(player, metadata)
    local data = metadata.value
    self.players[player].artist = data["xesam:artist"][1] or ""
    self.players[player].title = data["xesam:title"] or ""
    self.players[player].length = (data["mpris:length"] or 0) / 10^6
    self:update(player, false, true)
end

function playerctl:status_cb(player, status)
    self.players[player].status = status
    self:update(player, true)
end

function playerctl:player_exists(player)
    for _, lplayer in ipairs(self.manager.players) do
        if lplayer == player then return true end
    end
    return false
end

function playerctl:have_playing()
    for ilplayer, lplayer in pairs(self.players) do
        if lplayer.status and lplayer.status == "PLAYING" then
            return ilplayer
        end
    end
    return nil
end

function playerctl:playercount()
    local count = 0
    for _, __ in pairs(self.players) do
        count = count + 1
    end
    return count
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

    if self.players[player] == nil then self.players[player] = {} end
    self.players[player].status = player.playback_status
    self.players[player].artist = player:get_artist() or ''
    self.players[player].title = player:get_title() or ''
    self.players[player].length = (player.metadata.value["mpris:length"] or 0) / 10^6

    self:update(player, false, true)
end

function playerctl:update(player, checkactive, norefresh)
    if checkactive and player and self.active ~= player then
        self.active = player
        self:init_data(player)
        return
    end
    if not player then
        if not (self.active or self.manager.players[1]) then
            self.textbox:set_markup()
            return
        else
            player = self.active or self.manager.players[1]
        end
    end

    -- when a player gets paused or stopped show an active player if one exists
    local hplayer = self:have_playing()
    if hplayer ~= nil and (self.players[player].status == 'PAUSED' or self.players[player].status == 'STOPPED') then
        player = hplayer
    end

    if not playerctl:player_exists(player) then return end

    local artist = gears.string.xml_escape(self.players[player].artist)
    local title = gears.string.xml_escape(self.players[player].title)
    local position = (player:get_position() or 0) / 10^6
    if self.players[player].length == 0 and not norefresh then
        self.players[player].length = (player.metadata.value["mpris:length"] or 0) / 10^6
    end
    local length = self.players[player].length

    local separatorartist = (artist == '' or title == '') and '' or shiny.fg(beautiful.highlight, ' / ')
    local separatortime = (length == 0 or position == 0) and '' or shiny.fg(beautiful.highlight, ' / ')
    local separatorposition = (length == 0 or position == 0) and '' or shiny.fg(beautiful.highlight, ' | ')
    local space = (length == 0 and position == 0 and artist == '' and title == '') and '' or ' '

    if self.players[player].status == nil or self.players[player].status == '' then
        self.statusicon:set_image(beautiful.player_stop)
    elseif self.players[player].status == 'PAUSED' then
        self.statusicon:set_image(beautiful.player_pause)
    elseif self.players[player].status == 'PLAYING' then
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
    self.players = {}

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
