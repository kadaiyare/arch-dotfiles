-- Hyprland 0.56.2: migrated from hyprland.conf.
-- Keep hyprland.conf as a fallback while the installed version supports Hyprlang.
-- See README.md for validation, activation, and recovery.

local terminal = "foot"
local fileManager = "dolphin"
local menu = "wofi --show drun"
local mainMod = "SUPER"

-- Monitors: internal display on the left, HDMI display on the right.
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@120", position = "1920x0", scale = 1 })

hl.env("XCURSOR_SIZE", "48")
hl.env("LANG", "ja_JP.UTF-8")
hl.env("HYPRCURSOR_SIZE", "48")
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GTK_MODULES", "canberra-gtk-module")

-- Run only at session startup, not on ordinary config reloads.
hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.focus({ workspace = 2 }))
    for _, command in ipairs({
        "fcitx5 -d",
        "~/.config/hypr/scripts/event_sounds.sh",
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP LANG",
        "libinput-gestures-setup start",
        "swaync",
        "quickshell -p ~/.config/quickshell/nucleus-shell/shell.qml",
        "wl-paste --type text --watch cliphist store",
        "wl-paste --type image --watch cliphist store",
        "gnome-keyring-daemon --start --components=secrets",
    }) do
        hl.exec_cmd(command)
    end
end)

hl.config({
    xwayland = { force_zero_scaling = true },
    general = {
        gaps_in = 2,
        gaps_out = 8,
        border_size = 3,
        col = {
            active_border = {
                colors = { "rgb(89b4fa)", "rgb(cba6f7)", "rgb(f38ba8)" },
                angle = 45,
            },
            inactive_border = "rgb(45475a)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 0.85,
        inactive_opacity = 0.65,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
        },
    },
    animations = { enabled = true },
    master = { new_status = "master" },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
    },
    input = {
        kb_layout = "jp",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0.2,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            clickfinger_behavior = true,
            scroll_factor = 0.3,
        },
    },
    gestures = {
        workspace_swipe_distance = 300,
        workspace_swipe_invert = true,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio = 0.25,
        workspace_swipe_create_new = true,
        workspace_swipe_forever = true,
    },
})

-- Preserve the original curves, speeds, and animation styles.
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "myBezier" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 6, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
-- Special workspaces animate independently of window creation/destruction.
-- Negative vertical travel brings the terminal in from, and back out to, the top.
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidevert -100%" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 3, bezier = "easeInOutCubic", style =
"slidevert -100%" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace", scale = 0.75 })
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })
hl.device({ name = "brydge-w-touch-touchpad", sensitivity = 0.7 })

-- Applications and window actions.
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
-- Choose a persistent background for the current workspace.
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("quickshell -c nucleus-shell ipc call desktop wallpapers"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Nucleus: app shortcuts and a persistent drop-down terminal.
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("~/.local/bin/nucleus-apps"))
hl.bind(mainMod .. " + F12", hl.dsp.exec_cmd("~/.local/bin/nucleus-terminal"))
hl.workspace_rule({
    workspace = "special:nucleus-terminal",
    -- The drop-down keeps the original palettes while normal foot tests readable glass colors.
    on_created_empty =
    "foot --config ~/.config/foot/dropdown.ini --app-id=nucleus-dropdown-terminal --title='Nucleus Terminal'",
    animation = "slidevert -100%",
})
hl.window_rule({
    name = "nucleus-dropdown-terminal",
    match = { class = "^nucleus-dropdown-terminal$" },
    workspace = "special:nucleus-terminal",
    float = true,
    size = "(monitor_w*0.92) (monitor_h*0.55)",
    move = "(monitor_w*0.04) 60",
    animation = "slide top",
    opacity = "0.97 override 0.97 override",
})

for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
end

-- Workspace 10 is on the 0 key. Moving a window follows it, as before.
for workspace = 1, 10 do
    local key = workspace % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({ workspace = workspace, follow = true }))
end
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = true }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- The duplicate SUPER + left-button drag in the old config is registered once.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + SHIFT + mouse:272", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Lua long strings preserve shell quotes and command substitutions.
hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" "$HOME/Pictures/Screenshot=$(date +'%Y%m%d_%H%M%S').png"]]))

-- Hold SUPER + SHIFT + arrows / HJKL to resize by 10 pixels.
for _, resize in ipairs({
    { "right", 10, 0 }, { "left", -10, 0 },
    { "up",    0,  -10 }, { "down", 0, 10 },
    { "l", 10, 0 }, { "h", -10, 0 },
    { "k", 0,  -10 }, { "j", 0, 10 },
}) do
    hl.bind(mainMod .. " + SHIFT + " .. resize[1],
        hl.dsp.window.resize({ x = resize[2], y = resize[3], relative = true }),
        { repeating = true })
end

hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

-- Keep these actions in order: toggle floating, resize, then center.
hl.bind(mainMod .. " + V", function()
    if not hl.get_active_window() then
        return
    end
    local monitor = hl.get_active_monitor()
    if not monitor then
        return
    end
    -- Monitor width/height are physical pixels; resize uses logical pixels.
    local width, height = monitor.width, monitor.height
    if monitor.transform % 2 == 1 then
        width, height = height, width
    end
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.resize({
        x = math.floor(width / monitor.scale * 0.75),
        y = math.floor(height / monitor.scale * 0.75),
        relative = false,
    }))
    hl.dispatch(hl.dsp.window.center())
end)

hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
    name = "xwayland-initial-focus",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_initial_focus = true,
})

-- Readability trial: 26.67% white * 0.90 keeps the former 24% focused white tint.
hl.window_rule({
    name = "opacity-foot",
    match = { class = "^(foot)$" },
    opacity = "0.90 override 0.80 override",
})

-- Zed adds a faint white background tint; window opacity also fades text and icons.
hl.window_rule({
    name = "opacity-zed",
    match = { class = "^(dev.zed.Zed)$" },
    opacity = "0.90 override 0.80 override",
})

-- Official Discord uses compositor opacity; keep its own theme and application settings.
hl.window_rule({
    name = "opacity-discord",
    match = { class = "^(discord)$" },
    opacity = "0.80 override 0.70 override",
})

-- Use the same compositor blur path for foot, Zed and Discord (size=3, passes=3).
hl.window_rule({
    name = "blur-foot-zed",
    match = { class = "^(foot|dev[.]zed[.]Zed|discord)$" },
    no_blur = false,
    xray = false,
})

-- The remaining apps use the original opacity multipliers.
for _, rule in ipairs({
    { "dolphin",       "^(org.kde.dolphin)$",                "0.7 0.7" },
    { "thunar",        "^(thunar)$",                         "0.7 0.7" },
    { "code",          "^(Code)$",                           "0.7 0.7" },
    { "vesktop",       "^(vesktop)$",                        "0.75 0.75" },
    { "firefox",       "^(firefox)$",                        "0.85 0.85" },
    { "youtube-music", "^(com.github.th_ch.youtube_music)$", "0.75 0.75" },
}) do
    hl.window_rule({ name = "opacity-" .. rule[1], match = { class = rule[2] }, opacity = rule[3] })
end

for index, title in ipairs({ "File Operation Progress", "Properties", "Confirm to replace files" }) do
    hl.window_rule({
        name = "thunar-dialog-" .. index,
        match = { class = "^(thunar)$", title = "^(" .. title .. ")$" },
        float = true,
    })
end
hl.window_rule({ name = "vesktop-workspace", match = { class = "^(vesktop)$" }, workspace = "1" })

-- Keep Waydroid in the normal tiling layout (Android is set to 944x1009).
hl.window_rule({
    name = "waydroid-tiled",
    match = { class = "^(Waydroid|waydroid[.].*)$" },
    tile = true,
})

hl.layer_rule({
    name = "layerrule-1",
    match = { namespace = "wofi" },
    animation = "popin",
    blur = true,
    ignore_alpha = 0.5,
})
for index, namespace in ipairs({ "notifications", "swaync-control-center", "swaync-notification-window" }) do
    hl.layer_rule({
        name = "layerrule-" .. (index + 1),
        match = { namespace = namespace },
        blur = true,
        ignore_alpha = 0.5,
    })
end

-- Shared Mocha/Latte theme.
dofile(os.getenv("HOME") .. "/.config/hypr/catppuccin-theme.lua")
