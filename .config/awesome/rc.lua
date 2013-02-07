require("awful")
require("awful.autofocus")
require("awful.rules")
require("beautiful")
require("naughty")
require("awesompd/awesompd")
require("eminent")
local vicious = require("vicious")
local cal = require("cal")

-- Load menu entries
require("freedesktop.utils")
require("freedesktop.menu")

-- {{{ Error handling

if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end
do
    local in_error = false
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end

-- {{{ Variable definitions

-- Theme
beautiful.init(awful.util.getdir("config") .. "/darkasmysoul/theme.lua")

-- Default modkey.
modkey = "Mod4"

terminal = "urxvt"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor
browser = os.getenv("BROWSER") or "firefox"
fileman = "thunar"

local exec   = awful.util.spawn
local sexec  = awful.util.spawn_with_shell
local scount = screen.count()

batviciousarg = "BAT0"
--dateformat = "%a, %b %d %R"
dateformat = "%R"

freedesktop.utils.terminal = "urxvt"
freedesktop.utils.icon_theme = { 'Faenza','gnome' }

-- {{{ Menu
freedesktopmenu = freedesktop.menu.new()

mainmenu = awful.menu({ items =
                        {
                            { "Applications" , freedesktopmenu, beautiful.awesome_icon },
                            { terminal, terminal, theme.menu_terminal },
                            { browser, browser, theme.menu_wbrowser },
                            { fileman, fileman, theme.menu_fbrowser },
                            { "Rand Wall", "rWall", theme.menu_rwall },
                            { "Lock Screen", "xflock4", theme.menu_shutdown },
                            { "Exit", "obshutdown", theme.menu_reboot }
                         },
                         width = "135"
                      })

-- {{{ Naughty theme

naughty.config.default_preset.timeout          = 5
naughty.config.default_preset.screen           = 1
naughty.config.default_preset.position         = "top_right"
naughty.config.default_preset.width            = 315
naughty.config.default_preset.ontop            = true

-- {{{ Layouts

layouts =
{
    awful.layout.suit.floating,        --1
    awful.layout.suit.tile,            --2
    awful.layout.suit.tile.left,       --3
    awful.layout.suit.tile.bottom,     --4
    awful.layout.suit.fair,            --5
    awful.layout.suit.fair.horizontal, --6
    awful.layout.suit.max,             --7
    awful.layout.suit.max.fullscreen   --8
}

-- {{{ Tags

tags = {
  names  = { "1", "2", "3", "4", "5", "6", "7", "8", "9"},
  layout = { layouts[1], layouts[2], layouts[1],
             layouts[1], layouts[7], layouts[2],
             layouts[2], layouts[2], layouts[2] },
}
for s = 1, screen.count() do
  tags[s] = awful.tag(tags.names, s, tags.layout)
    end

-- {{{ Wibox

-- Create a systray
systray = widget({ type = "systray", align = "center" })

-- Create a wibox for each screen and add it
wibox = {}
promptbox = {}
layoutbox = {}
taglist = {}
taglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
tasklist = {}
tasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    promptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    layoutbox[s] = awful.widget.layoutbox(s)
    layoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    taglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, taglist.buttons)

    -- Create a tasklist widget
    tasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, tasklist.buttons)

--{{{ Widgets

    --{{---| MPD widget |-----------------------------
mpdlabel = widget({type = "textbox" })
mpdlabel.text = '<span foreground="#8f5b5b"> MPD </span>'
mpdlabel.bg = "#222222"
mpdlabel:buttons(awful.util.table.join(
  awful.button({ }, 1, function () exec("urxvt -e ncmpcpp") end)
))

mpdwidget = widget({ type = "textbox"})

mpdwidget = awesompd:create()
mpdwidget.font = beautiful.font
mpdwidget.scrolling = true
mpdwidget.output_size = 50
mpdwidget.show_album_cover = true
mpdwidget.update_interval = 3
mpdwidget.path_to_icons = awful.util.getdir("config") .. "/darkasmysoul/icons/awesompd"
mpdwidget.mpd_config = "/home/orthos/.mpdconf"
mpdwidget.album_cover_size = 60
mpdwidget.browser = browser
mpdwidget.ldecorator = ""
mpdwidget.rdecorator = ""
mpdwidget:register_buttons({
   { "", awesompd.MOUSE_LEFT, mpdwidget:command_playpause() },
   { "Control", awesompd.MOUSE_SCROLL_UP, mpdwidget:command_prev_track() },
   { "Control", awesompd.MOUSE_SCROLL_DOWN, mpdwidget:command_next_track() },
   { "", awesompd.MOUSE_SCROLL_UP, mpdwidget:command_volume_up() },
   { "", awesompd.MOUSE_SCROLL_DOWN, mpdwidget:command_volume_down() },
   { "", awesompd.MOUSE_RIGHT, mpdwidget:command_show_menu() }
})
mpdwidget:run()

    --{{---| Battery widget |-----------------------
batlabel = widget({ type = "textbox" })
batlabel.bg = "#222222"
batlabel.text = '<span foreground="#7c915a"> BAT </span>'
batlabel:buttons(awful.util.table.join(
  awful.button({ }, 1, function () exec("xfce4-power-manager-settings") end)
))

battime = widget({ type = 'textbox' })
batwidget = widget({ type = "textbox" })
--vicious.register(batwidget, vicious.widgets.bat, "$1$2%", 61, "BAT0")
vicious.register(batwidget, vicious.widgets.bat,
  function (widget, args)
  batremain = args[3]
  batstate = args[1]
  batcharge = args[2]
  if batstate == "Charging" then
    battime.text = '+' ..batcharge.. ''
    battime.visible = true
  elseif batstate == "Discharging" then
    battime.text = '-' ..batcharge.. ''
    battime.visible = true
  else battime.visible = false
  end
  if batstate == "Discharging" and batcharge < 10 then
    naughty.notify({ title = "Battery Warning\n", text = "%" .. batcharge .. " " .. batremain .. " REMAINING! CHARGE MUH BATTERIES!!", timeout = 0, position = "top_right", fg = beautiful.fg_urgent, bg = beautiful.bg_urgent })
  end
  if batstate == "Discharging" and batcharge < 4 then
    exec("gksudo shutdown -h now")
  end
  if batstate == "Full" then
    batlabel.text = "FULL"
  else
    batwidget.visible = true
  end
  return args[1]..args[2].."%"
  end, 61, batviciousarg)

battooltip = awful.tooltip({
objects = { K },
 timer_function = function()
   --local acpibat = io.popen("acpi -V|head -n1")
   --local acpibatstatus = acpibat:read("*all")
   --acpibat:close()
   --return ' \n '..acpibatstatus.. ..' '
 if batstate and batcharge then
  return ' Left : %' ..batcharge.. ' \n Time : ' ..batremain.. ' \n State: ' ..batstate.. ' \n'
 else
  return ' \n n\\a \n'
 end
end,
})

battooltip:add_to_object(batwidget)
battooltip:add_to_object(batlabel)

    --{{---| WiFi widget |-------------------------
wifilabel = widget({ type = "textbox" })
wifilabel.text = '<span foreground="#9d4e6e"> NET </span>'
wifilabel.bg = "#222222"
wifilabel:buttons(awful.util.table.join(
   awful.button({ }, 1, function () exec("urxvt -e wicd-curses") end)
))

netwidget = widget({ type = "textbox" })
vicious.register(netwidget, vicious.widgets.net,
  function (widget, args)
  netdspeed = args["{wlp2s0 down_kb}"]
  netuspeed = args["{wlp2s0 up_kb}"]
  return '<span color="#c4b1b5">' ..netdspeed.. ' ↓↑ ' ..netuspeed.. '</span>'
  end, 6)

nettooltip = awful.tooltip({
--objects = { K },
 timer_function = function()
 if netdspeed then
   return '\n Down: ' ..math.floor(netdspeed / 1).. 'Kb/s \n Up: ' ..math.floor(netuspeed / 1).. 'Kb/s \n'
 else
   return ' \n n\\a \n'
 end
end,
})

nettooltip:add_to_object(wifilabel)

wifiwidget = widget({ type = "textbox" })
vicious.register(wifiwidget, vicious.widgets.wifi, "${linp}%", 121, "wlp2s0")

wifitooltip = awful.tooltip({
objects = { K },
timer_function = function()
 local data = wicdcli()
 if data then
   return "\n " ..data.. " \n"
 else
   return ' \n n\\a \n'
 end
end,
})

wifitooltip:add_to_object(wifiwidget)

function wicdcli()
 local f = io.popen("wicd-cli -y -d")
 local fi = f:read("*all")
 f:close()
 if fi then
   return fi
 end
end

    --{{---| Volume widget |-----------------------------
vollabel = widget({ type = 'textbox' })
vollabel.text = '<span foreground="#424e60"> VOL </span>'
vollabel.bg = "#222222"
awful.widget.layout.margins[vollabel] = { right = 1 }
vollabel:buttons(awful.util.table.join(
   awful.button({ }, 1, function () exec("urxvt -e alsamixer") end)
))

volwidget = widget({ type = "textbox"})
vicious.register(volwidget, vicious.widgets.volume,
  function(widget, args)
    local label = { ["♫"] = "", ["♩"] = " M" }
    return args[1] .. label[args[2]]
  end, 2, "Master")
volwidget:buttons(awful.util.table.join(
   awful.button({ }, 1, function () exec("amixer -q -c 0 sset Master toggle") end),
   awful.button({ }, 4, function () exec("amixer -q -c 0 sset Master 2%+") end),
   awful.button({ }, 5, function () exec("amixer -q -c 0 sset Master 2%-") end)
))


voltip = awful.tooltip({
objects = { K },
 timer_function = function()
 local volume = io.popen("amixer get Master")
 local line=volume:read()
 while line do
  local volact = string.match(line, '.+%[(%d+%%).+')
   if volact then
    return ' Master: ' ..volact.. ' '
   end
  line=volume:read()
 end
 io.close(volume)
end,
})
voltip:add_to_object(volwidget)
voltip:add_to_object(vollabel)

    --{{---| Clock widget |-----------------------------
clocklabel = widget({ type = "textbox" })
clocklabel.text = '<span foreground="#9e8762"> CLK </span>'
clocklabel.bg = "#222222"
clockwidget = widget({ type = "textbox" })
--clockwidget.width = 102
clockwidget.align = "center"
vicious.register(clockwidget, vicious.widgets.date, dateformat, 61)
cal.register(clockwidget)

    --{{---| Separators |--------------------------------
spacer = widget({type = "textbox" })
spacer.text = " "
separator = widget({ type = "textbox" })
separator.text = '<span foreground="#8f5b5b">|</span>'

--{{{ Panel
--
-- Create the wibox
wibox[s] = awful.wibox(
            {
              position = "top",
              height = "16",
              fg = beautiful.fg_normal,
              bg = beautiful.bg_normal,
              screen = s
            })

-- Add widgets to the wibox - order matters
wibox[s].widgets = {
     {
         taglist[s],
         separator,
--         spacer,
         layoutbox[s],
         spacer,
         promptbox[s],
         layout = awful.widget.layout.horizontal.leftright
     },
     spacer,
     systray,
     spacer,
     separator,
     spacer,
     clockwidget,
     spacer,
     clocklabel,
     spacer,
--     netwidget,
--     spacer,
     wifiwidget,
     spacer,
     wifilabel,
     spacer,
     battime,
     batwidget,
     spacer,
     batlabel,
     spacer,
     volwidget,
     spacer,
     vollabel,
     spacer,
     mpdwidget.widget,
     spacer,
     mpdlabel,
     spacer,
     tasklist[s],
     layout = awful.widget.layout.horizontal.rightleft
}
end

-- {{{ Mouse bindings

root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

-- {{{ Key bindings

globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- {{{---| Custom |---------------------------------------------------------------------
    awful.key({ modkey },            "e",      function () exec(fileman) end),
    awful.key({ modkey },            "b",      function () exec(browser) end),
    awful.key({ "Mod1" },            "F2",     function () exec("xfce4-appfinder") end),
    awful.key({ "Control" },         "Print",  function () exec("capscr",false) end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () exec(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () promptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  promptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

--Client Manipulation
clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),
    awful.key({ modkey, "Shift" }, "t", function (c)
        if   c.titlebar then awful.titlebar.remove(c)
        else awful.titlebar.add(c, { modkey = modkey }) end
    end),
    awful.key({ modkey, "Shift" }, "f", function (c) if awful.client.floating.get(c)
        then awful.client.floating.delete(c);    awful.titlebar.remove(c)
        else awful.client.floating.set(c, true); awful.titlebar.add(c) end
    end)
)

root.keys(mpdwidget:append_global_keys(globalkeys))

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)

-- {{{ Rules

awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     size_hints_honor = false,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "mplayer2" },
      properties = { floating = true } },
    { rule = { class = "smplayer" },
      properties = { floating = true } },
    { rule = { class = "mplayer" },
      properties = { floating = true } },
    { rule = { class = "mpv" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { instance = "xfce4-appfinder" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    { rule = { class = "Firefox" },
      properties = { tag = tags[1][2] } },
    { rule = { instance = "plugin-container" },
     properties = { floating = true } },
    { rule = { instance = "exe" },
     properties = { floating = true } },
}

-- {{{ Signals

-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

--{{{ Autostart

function run_oncewa(prg) if not prg then do return nil end end
    awful.util.spawn_with_shell('ps ux | grep -v grep | grep -F ' .. prg .. ' || ' .. prg .. ' &') end

os.execute("pkill compton")

sexec("cmptn")
--sexec("run_once xfce4-power-manager")
--sexec("run_oncewa thunar --daemon")
--sexec("xscreensaver -no-splash")

--sexec("run_once mpdas")
--sexec("run_once lxpolkit")
sexec("run_once thunderbird")

sexec("tmux-daemonize rtorrent")
sexec("sleep 10 && irc_start")
sexec("sleep 10 && urxvt -g 110x35 -e tmux a -t rtorrent")

-- }}}
