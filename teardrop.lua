----------------------------------------------------------------
-- Drop-down applications manager for the awesome window manager
----------------------------------------------------------------
-- Blame: Adrian C. <anrxc@sysphere.org>
-- Licensed under the WTFPL version 2
--   * http://sam.zoy.org/wtfpl/COPYING
-- modified by shdb
----------------------------------------------------------------
-- To use this module add:
--   require("teardrop")
-- to the top of your rc.lua, and call it from a keybinding:
--   teardrop(prog, vert, horiz, width, height, sticky, screen)
--
-- Parameters:
--   prog   - Program to run; "urxvt", "gmrun", "thunderbird"
--   vert   - Vertical; "bottom", "center" or "top" (default)
--   horiz  - Horizontal; "left", "right" or "center" (default)
--   width  - Width in absolute pixels, or width percentage
--            when <= 1 (1 (100% of the screen) by default)
--   height - Height in absolute pixels, or height percentage
--            when <= 1 (0.25 (25% of the screen) by default)
--   sticky - Visible on all tags, true by default
--   screen - Screen (optional), mouse.screen by default
----------------------------------------------------------------

-- Grab environment
local pairs = pairs
local awful = require("awful")
local beautiful = require("beautiful")
local setmetatable = setmetatable
local math = math
local capi = {
    mouse = mouse,
    client = client,
    screen = screen
}

-- Teardrop: Drop-down applications manager for the awesome window manager
module("teardrop")

local dropdown = {}

-- Create a new window for the drop-down application when it doesn't
-- exist, or toggle between hidden and visible states when it does
function toggle(prog, displacement, vert, horiz, width, height, sticky, screen)
    local displacement = displacement or 0
    local vert         = vert         or "top"     -- top, bottom or center
    local horiz        = horiz        or "center"  -- left, right or center
    local width        = width        or 1
    local height       = height       or 0.21
    local sticky       = sticky       or true
    local screen       = screen       or capi.mouse.screen

    local function removefromtags(c)
        local ctags = c:tags()
        for i, t in pairs(ctags) do
            ctags[i] = nil
        end
        c:tags(ctags)
    end

    if not dropdown[prog] then
        dropdown[prog] = {}

        -- Add unmanage signal for teardrop programs
        capi.client.connect_signal("unmanage", function (c)
            for scr, cl in pairs(dropdown[prog]) do
                if cl == c then
                    dropdown[prog][scr] = nil
                end
            end
        end)
    end

    if not dropdown[prog][screen] then
        spawnw = function (c)
            capi.client.disconnect_signal("manage", spawnw)
            removefromtags(c)
            dropdown[prog][screen] = c

            -- Teardrop clients are floaters
            c.floating = true
            c.border_width = beautiful.border_width

            -- Client geometry and placement
            local screengeom = capi.screen[screen].workarea

            if width  <= 1 then width  = math.floor(screengeom.width  * width  - 2 * beautiful.border_width + 0.5) end
            if height <= 1 then height = math.floor(screengeom.height * height + 0.5) end

            if     horiz == "left"  then x = displacement
            elseif horiz == "right" then x = screengeom.width - width + displacement - 2 * beautiful.border_width
            else   x = (screengeom.width - (width + 2 * beautiful.border_width))/2 end

            if     vert == "bottom" then y = screengeom.height - height - displacement + beautiful.titlebar_height - beautiful.border_width
            elseif vert == "center" then y = (screengeom.height - height + beautiful.titlebar_height + 2 * beautiful.border_width)/2
            else   y = beautiful.titlebar_height + displacement end

            -- Client properties
            c:geometry({ x = x, y = y, width = width, height = height })
            c.ontop = true
            c.above = true
            c.skip_taskbar = true
            if sticky then c.sticky = true end
            if c.titlebar then awful.titlebar.remove(c) end

            c:move_to_tag(awful.tag.selected(screen))
            c:raise()
            capi.client.focus = c
        end

        -- Add manage signal and spawn the program
        capi.client.connect_signal("manage", spawnw)
        awful.util.spawn(prog, false)
    else
        -- Get a running client
        c = dropdown[prog][screen]

        -- Switch the client to the current workspace
        if c:isvisible() == false then
            c.hidden = true;
            c:move_to_tag(awful.tag.selected(screen))
        end

        -- Focus and raise if hidden
        if c.hidden then
            -- Make sure it is centered
            --if vert  == "center" then awful.placement.center_vertical(c)   end
            --if horiz == "center" then awful.placement.center_horizontal(c) end
            c.hidden = false
            c:raise()
            capi.client.focus = c
        else -- Hide and detach tags if not
            c.hidden = true
        end
        removefromtags(c)
    end
end

setmetatable(_M, { __call = function(_, ...) return toggle(...) end })
