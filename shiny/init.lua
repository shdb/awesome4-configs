local dpi       = require("beautiful.xresources").apply_dpi
local naughty   = require("naughty")
local beautiful = require("beautiful")
local math      = { floor = math.floor }
local string    = string
local table     = table
module("shiny")

function fg(color, text)
    color = color or beautiful.fg_normal
    text = text or ""
    return '<span color="' .. color .. '">' .. text .. '</span>'
end

function bold(text)
    return '<b>' .. text .. '</b>'
end

function remove_notify(notify)
    if notify then
        naughty.destroy(notify)
        notify = nil
    end
end

function splitbywhitespace(str)
    values = {}
    start = 1
    splitstart, splitend = string.find(str, ' ', start)

    while splitstart do
        m = string.sub(str, start, splitstart - 1)
        if m:gsub(' ', '') ~= '' then
            table.insert(values, m)
        end

        start = splitend + 1
        splitstart, splitend = string.find(str, ' ', start)
    end

    m = string.sub(str, start)
    if m:gsub(' ','') ~= '' then
        table.insert(values, m)
    end

    return values
end

function round_num(num, idp, dot)
    local mult = 10^(idp or 0)
    num = math.floor(num * mult + 0.5) / mult
    if dot then
        num = math.floor(num + 0.5)
    end
    return num
end

function lpaddto(str, num)
    while string.len(str) < num do
        str = ' ' .. str
    end
    return str
end
