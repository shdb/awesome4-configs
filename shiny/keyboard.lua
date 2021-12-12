local awful   = require("awful")
local naughty = require("naughty")
local gears   = require("gears")

local io = {
    popen = io.popen,
    close = io.close
}
local string = string

keyboard = {}

local function getkb()
    local f = io.popen("setxkbmap -print")
    for line in f:lines() do
        local _, _, lo = string.find(line, "+(..)+")
        if lo then
            f:close()
            return lo
        end
    end
    f:close()
end

function keyboard.toggle()
    if not layout then
        layout = getkb()
    end
    if layout == "ch" then
        awful.spawn.with_shell("setxkbmap -layout us; "
                .. "xmodmap " .. gears.filesystem.get_dir("config") .. "/../../.Xmodmap")
        layout = "us"
    else
        awful.spawn.with_shell("setxkbmap -layout ch; "
                .. "xmodmap " .. gears.filesystem.get_dir("config") .. "/../../.Xmodmap")
        layout = "ch"
    end
    naughty.notify {
        title = "keyboard layout",
        text  = "current layout: " .. layout,
        timeout = 2
    }
end

return setmetatable({}, { __call = function(_, ...) return keyboard end })
