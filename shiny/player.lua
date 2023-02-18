local lgi       = require("lgi")
local gears     = require('gears')
local shiny     = require("shiny")
local wibox     = require("wibox")
local naughty   = require("naughty")
local awful     = require("awful")
local beautiful = require("beautiful")
local math      = require('math')

player = { mt = {} }


function player:formattime(time)
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

function player:init_player(name)
    local playerctl = self.Playerctl.Player.new_from_name(name)
    self.manager:manage_player(playerctl)
    playerctl.on_metadata = function(playerctl, metadata)
        self:metadata_cb(playerctl, metadata)
    end

    playerctl.on_playback_status = function(playerctl, status)
        self:status_cb(playerctl, status)
    end

    playerctl.on_seeked = function(playerctl, position)
        self:update(playerctl, true)
    end

    playerctl.on_exit = function(playerctl)
        self.textbox:set_markup('')
        self.active = nil
        gears.timer.delayed_call(function()
            self:init_data()
        end)
    end

    self.active = playerctl
    self:init_data(playerctl)
end

function player:metadata_cb(playerctl, metadata)
    local data = metadata.value
    self.title = data["xesam:title"] or ""
    self.artist = data["xesam:artist"][1] or ""
    self.length = (data["mpris:length"] or 0) / 10^6
    self:update(playerctl)
end

function player:status_cb(playerctl, status)
    self.status = status
    self:update(playerctl, true)
end

function player:playerctl_exists(playerctl)
    for _, lplayerctl in ipairs(self.manager.players) do
        if lplayerctl == playerctl then return true end
    end
    return false
end

function player:init_data(playerctl)
    if not playerctl then
        if not (self.active or self.manager.players[1]) then
            self.textbox:set_markup()
            return
        else
            playerctl = self.active or self.manager.players[1]
        end
    end

    if not player:playerctl_exists(playerctl) then return end

    self.status = playerctl.playback_status
    self.artist = playerctl:get_artist() or ''
    self.title = playerctl:get_title() or ''
    self.length = (playerctl.metadata.value["mpris:length"] or 0) / 10^6

    self:update(playerctl)
end

function player:update(playerctl, checkactive)
    if checkactive and playerctl and self.active ~= playerctl then
        self.active = playerctl
        self:init_data(playerctl)
    end
    if not playerctl then
        if not (self.active or self.manager.players[1]) then
            self.textbox:set_markup()
            return
        else
            playerctl = self.active or self.manager.players[1]
        end
    end

    if not player:playerctl_exists(playerctl) then return end

    local artist = gears.string.xml_escape(self.artist)
    local title = gears.string.xml_escape(self.title)
    local position = (playerctl:get_position() or 0) / 10^6
    if self.length == 0 then
        self.length = (playerctl.metadata.value["mpris:length"] or 0) / 10^6
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

function player:playpause(playerctl)
    playerctl = playerctl or self.active or self.manager.players[1]
    if not playerctl then return end
    playerctl:play_pause()
end

function player:play(playerctl)
    playerctl = playerctl or self.active or self.manager.players[1]
    if not playerctl then return end
    playerctl:play()
end

function player:pause(playerctl)
    playerctl = playerctl or self.active or self.manager.players[1]
    if not playerctl then return end
    playerctl:pause()
end

function player:next(playerctl)
    playerctl = playerctl or self.active or self.manager.players[1]
    if not playerctl then return end
    playerctl:next()
end

function player:previous(playerctl)
    playerctl = playerctl or self.active or self.manager.players[1]
    if not playerctl then return end
    playerctl:previous()
end

function player:seekfw(amount, playerctl)
    amount = amount or 5
    playerctl = playerctl or self.active or self.manager.players[1]
    if not playerctl then return end
    playerctl:seek(amount * 10^6)
end

function player:seekbw(amount, playerctl)
    amount = amount or 5
    playerctl = playerctl or self.active or self.manager.players[1]
    if not playerctl then return end
    playerctl:seek('-' .. amount * 10^6)
end

function player:stop(playerctl)
    playerctl = playerctl or self.active or self.manager.players[1]
    if not playerctl then return end
    playerctl:stop()
end

function player:new()
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

return setmetatable({}, { __call = function(_, ...) return player:new(...) end })
