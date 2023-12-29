-------------------------------
--  "Zenburn" awesome theme  --
--    By Adrian C. (anrxc)   --
-------------------------------

local themes_path = require("gears.filesystem").get_configuration_dir() .. "themes/"
local path = themes_path .. "shdb/"
local dpi = require("beautiful.xresources").apply_dpi

-- {{{ Main
local theme = {}
--theme.wallpaper = themes_path .. "shdb/zenburn-background.png"
-- }}}

-- {{{ Styles
theme.font      = "DejaVu Sans Mono 9"
--theme.font      = "snap 7"

theme.highlight  = "#FFCC44"

theme.fg_normal  = "#449900"
theme.fg_focus   = "#66FF00"
theme.fg_urgent  = "#CC0000"

--theme.bg_normal  = "#3F3F3F"
theme.bg_normal  = "#171717"
theme.bg_focus   = "#1E2320"
theme.bg_urgent  = "#3F3F3F"
theme.bg_systray = theme.bg_normal

theme.graph_bg      = "#333333"
theme.graph_center  = "#779900"
theme.graph_end     = "#ff9900"

-- {{{ Borders
theme.useless_gap   = dpi(0)
theme.border_width  = dpi(2)
--theme.border_normal = "#3F3F3F"
--theme.border_focus  = "#6F6F6F"
--theme.border_marked = "#CC9393"
theme.border_normal = "#338000"
theme.border_focus  = "#66FF00"
theme.border_marked = "#66FF00"
-- }}}

-- {{{ Titlebars
theme.titlebar_bg_focus  = "#3F3F3F"
theme.titlebar_bg_normal = "#3F3F3F"
theme.titlebar_height    = 16
-- }}}

theme.battery        = path .. "icons/battery.png"
theme.battery_yellow = path .. "icons/battery_yellow.png"
theme.battery_red    = path .. "icons/battery_red.png"
theme.brightness     = path .. "icons/brightness.png"
theme.volume         = path .. "icons/volume.png"
theme.muted          = path .. "icons/muted.png"
theme.cpu            = path .. "icons/cpu.png"
theme.temp           = path .. "icons/temp.png"
theme.mail           = path .. "icons/mail.png"
theme.mem            = path .. "icons/mem.png"
theme.wireless       = path .. "icons/wireless.png"
theme.network        = path .. "icons/network.png"
theme.player_play    = path .. "icons/player_play.png"
theme.player_pause   = path .. "icons/player_pause.png"
theme.player_stop    = path .. "icons/player_stop.png"
theme.openvpn        = path .. "icons/openvpn.png"

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- [taglist|tasklist]_[bg|fg]_[focus|urgent|occupied|empty|volatile]
-- titlebar_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- Example:
--theme.taglist_bg_focus = "#CC9393"
-- }}}

-- {{{ Widgets
-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.fg_widget        = "#AECF96"
--theme.fg_center_widget = "#88A175"
--theme.fg_end_widget    = "#FF5656"
--theme.bg_widget        = "#494B4F"
--theme.border_widget    = "#3F3F3F"
-- }}}

-- {{{ Mouse finder
theme.mouse_finder_color = "#CC9393"
-- mouse_finder_[timeout|animate_timeout|radius|factor]
-- }}}

-- {{{ Menu
-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_height = dpi(16)
theme.menu_width  = dpi(100)
-- }}}

-- {{{ Icons
-- {{{ Taglist
theme.taglist_squares_sel   = themes_path .. "shdb/taglist/squarefz.png"
theme.taglist_squares_unsel = themes_path .. "shdb/taglist/squarez.png"
--theme.taglist_squares_resize = "false"
-- }}}

-- {{{ Misc
theme.awesome_icon           = themes_path .. "shdb/awesome-icon.png"
theme.menu_submenu_icon      = themes_path .. "shdb/submenu.png"
-- }}}

-- {{{ Layout
theme.layout_tile       = themes_path .. "shdb/layouts/tile.png"
theme.layout_tileleft   = themes_path .. "shdb/layouts/tileleft.png"
theme.layout_tilebottom = themes_path .. "shdb/layouts/tilebottom.png"
theme.layout_tiletop    = themes_path .. "shdb/layouts/tiletop.png"
theme.layout_fairv      = themes_path .. "shdb/layouts/fairv.png"
theme.layout_fairh      = themes_path .. "shdb/layouts/fairh.png"
theme.layout_spiral     = themes_path .. "shdb/layouts/spiral.png"
theme.layout_dwindle    = themes_path .. "shdb/layouts/dwindle.png"
theme.layout_max        = themes_path .. "shdb/layouts/max.png"
theme.layout_fullscreen = themes_path .. "shdb/layouts/fullscreen.png"
theme.layout_magnifier  = themes_path .. "shdb/layouts/magnifier.png"
theme.layout_floating   = themes_path .. "shdb/layouts/floating.png"
theme.layout_cornernw   = themes_path .. "shdb/layouts/cornernw.png"
theme.layout_cornerne   = themes_path .. "shdb/layouts/cornerne.png"
theme.layout_cornersw   = themes_path .. "shdb/layouts/cornersw.png"
theme.layout_cornerse   = themes_path .. "shdb/layouts/cornerse.png"
-- }}}

-- {{{ Titlebar
theme.titlebar_close_button_focus  = themes_path .. "shdb/titlebar/close_focus.png"
theme.titlebar_close_button_normal = themes_path .. "shdb/titlebar/close_normal.png"

theme.titlebar_minimize_button_normal = themes_path .. "default/titlebar/minimize_normal.png"
theme.titlebar_minimize_button_focus  = themes_path .. "default/titlebar/minimize_focus.png"

theme.titlebar_ontop_button_focus_active  = themes_path .. "shdb/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active = themes_path .. "shdb/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive  = themes_path .. "shdb/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive = themes_path .. "shdb/titlebar/ontop_normal_inactive.png"

theme.titlebar_sticky_button_focus_active  = themes_path .. "shdb/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active = themes_path .. "shdb/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive  = themes_path .. "shdb/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive = themes_path .. "shdb/titlebar/sticky_normal_inactive.png"

theme.titlebar_floating_button_focus_active  = themes_path .. "shdb/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active = themes_path .. "shdb/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive  = themes_path .. "shdb/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive = themes_path .. "shdb/titlebar/floating_normal_inactive.png"

theme.titlebar_maximized_button_focus_active  = themes_path .. "shdb/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active = themes_path .. "shdb/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive  = themes_path .. "shdb/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = themes_path .. "shdb/titlebar/maximized_normal_inactive.png"
-- }}}
-- }}}

return theme

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
