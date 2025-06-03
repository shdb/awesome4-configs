-- apps like mplayer should always be ontop
-- mplayer looses the ontop flag when changing from fullscreen to windowed mode.

local pairs, screen, mouse, client
    = pairs, screen, mouse, client

-- keeps apps on top
local topapps = {
    ["Gkrellm"]  = true,
    ["MPlayer"]  = true,
    ["mplayer2"] = true,
    ["mpv"]      = true,
    ["Toolkit"]  = true,
}

local function update(c)
    local lscreen = c and c.screen or mouse.screen
    for _, ttag in pairs(lscreen.selected_tags) do
        for _, tclient in pairs(ttag:clients()) do
            if (topapps[tclient.class] or topapps[tclient.instance]) and not tclient.fullscreen then
                tclient.ontop = true
                tclient:raise()
            end
        end
    end
end

client.connect_signal("focus", function(c) update(c) end)
client.connect_signal("unfocus", function(c) update(c) end)
client.connect_signal("unmanage", function(c) update(c) end)

return topapps
