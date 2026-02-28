{
  config,
  options,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    types
    lists
    attrsets
    ;
  inherit (builtins) elemAt;

  cfg = config.modules.graphics.niri;

  wpaperctl = "${pkgs.wpaperd}/bin/wpaperctl";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
in
{
  options.modules.graphics.niri = {
    enable = mkEnableOption "niri";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.wl-clipboard-rs
      # pkgs.xorg.xrdb
    ];

    programs = {
      niri.enable = true;
      # hyprland = {
      #   enable = true;
      #   # withUWSM = true;
      # };

      foot = {
        enable = true;
        enableZshIntegration = true;
      };

    };

    security.polkit.enable = true; # polkit
    # services.gnome.gnome-keyring.enable = true; # secret service
    # security.pam.services.swaylock = {};
    # security = {
    #   pam.services.hyprlock = {};
    # };

    services.playerctld.enable = true;

    environment.sessionVariables = {
      # use integrated gpu for niri
      # WLR_DRM_DEVICES = "/dev/dri/card2:/dev/dri/card1";
      # AQ_DRM_DEVICES = "/dev/dri/card2:/dev/dri/card1";

      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      # WLR_NO_HARDWARE_CURSORS = "1";
      # WLR_BACKEND = "vulkan";
      # XDG_SESSION_TYPE = "wayland";
      # QT_QPA_PLATFORM = "wayland";
      # CLUTTER_BACKEND = "wayland";
      # GDK_BACKEND = "wayland";
      # SDL_VIDEODRIVER = "wayland";
    };

    system.user.hm = {
      xdg.configFile."niri/config.kdl".text = ''
        spawn-at-startup "${pkgs.waybar}/bin/waybar"
        spawn-at-startup "bash" "-c" "${pkgs.wpaperd}/bin/wpaperd -d"

        prefer-no-csd

        spawn-at-startup "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
        // Next release will be:
        // xwayland-satellite {
        //   path "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
        // }

        environment {
          _JAVA_AWT_WM_NONREPARENTING "1"
          ELECTRON_OZONE_PLATFORM_HINT "auto"
          DISPLAY ":0"
        }

        hotkey-overlay {
          skip-at-startup
        }

        layout {
          gaps 12
          struts {
            left 40
            right 40
            top 30
            bottom 30
          }
          always-center-single-column
          center-focused-column "on-overflow"
          default-column-display "tabbed"
          tab-indicator {
            hide-when-single-tab
            width 8
            gap 8
            length total-proportion=1.0
            position "top"
            place-within-column
          }
          default-column-width {}
          focus-ring {
            width 3;
            inactive-color "${config.system.pretty.theme.colors.window.border.hexRGBA}";
            active-color   "${config.system.pretty.theme.colors.window.active_border.hexRGBA}";
            urgent-color   "${config.system.pretty.theme.colors.window.urgent_border.hexRGBA}";
          }
          shadow {
            on
            softness 24;
            spread 6;
            offset x=12 y=12;
            draw-behind-window true;
            color "${config.system.pretty.theme.colors.window.shadow.hexRGBA}";
          }
          insert-hint {
            color "${config.system.pretty.theme.colors.cursor.accent.hexRGB}80";
          }
        }

        window-rule {
          geometry-corner-radius 12
          clip-to-geometry true
        }
        input {
          keyboard {
            xkb {
              layout "${config.system.keyboard.kb_layout}";
              options "${elemAt config.system.keyboard.kb_options 0}";
            }
          }
        }

        workspace "scratch"
        workspace "work"
        workspace "web"
        workspace "chat"

        output "eDP-1" {
            // off
            mode "1920x1200@165.019"
            scale 1.0
            focus-at-startup
        }

        binds {
          Mod+Return { spawn "${pkgs.foot}/bin/foot"; }
          Mod+D { spawn "bash" "-c" "${pkgs.tofi}/bin/tofi-run | xargs niri msg action spawn --"; }
          Mod+O repeat=false { toggle-overview; }
          Mod+Shift+Q repeat=false { close-window; }
          Mod+Shift+F { fullscreen-window; }
          Mod+Shift+Space { toggle-window-floating; }
          Mod+Shift+M { quit; }
          Mod+Shift+P { power-off-monitors; }

          Mod+1 { focus-workspace "scratch"; }
          Mod+2 { focus-workspace "work"; }
          Mod+3 { focus-workspace "web"; }
          Mod+4 { focus-workspace "chat"; }
          Mod+5 { focus-workspace 5; }
          Mod+6 { focus-workspace 6; }
          Mod+7 { focus-workspace 7; }
          Mod+8 { focus-workspace 8; }
          Mod+Shift+1 { move-column-to-workspace "scratch"; }
          Mod+Shift+2 { move-column-to-workspace "work"; }
          Mod+Shift+3 { move-column-to-workspace "web"; }
          Mod+Shift+4 { move-column-to-workspace "chat"; }
          Mod+Shift+5 { move-column-to-workspace 5; }
          Mod+Shift+6 { move-column-to-workspace 6; }
          Mod+Shift+7 { move-column-to-workspace 7; }
          Mod+Shift+8 { move-column-to-workspace 8; }
          Mod+Tab       { move-workspace-down; }
          Mod+Shift+Tab { move-workspace-up; }

          Mod+Left  { focus-column-left; }
          Mod+Down  { focus-window-down; }
          Mod+Up    { focus-window-up; }
          Mod+Right { focus-column-right; }
          Mod+H     { focus-column-left; }
          Mod+J     { focus-window-down; }
          Mod+K     { focus-window-up; }
          Mod+L     { focus-column-right; }

          Mod+Ctrl+Left  { move-column-left; }
          Mod+Ctrl+Down  { move-window-down; }
          Mod+Ctrl+Up    { move-window-up; }
          Mod+Ctrl+Right { move-column-right; }
          Mod+Ctrl+H     { move-column-left; }
          Mod+Ctrl+J     { move-window-down; }
          Mod+Ctrl+K     { move-window-up; }
          Mod+Ctrl+L     { move-column-right; }

          Mod+Shift+H { set-column-width "-10%"; }
          Mod+Shift+L { set-column-width "+10%"; }
          Mod+Shift+J { set-window-height "-10%"; }
          Mod+Shift+K { set-window-height "+10%"; }

          Mod+Shift+WheelScrollDown { focus-workspace-down; }
          Mod+Shift+WheelScrollUp   { focus-workspace-up; }
          Mod+WheelScrollDown       { focus-column-right; }
          Mod+WheelScrollUp         { focus-column-left; }

          Mod+Ctrl+F { expand-column-to-available-width; }
          Mod+Ctrl+C { center-column; }
          Mod+Ctrl+V { center-visible-columns; }

          XF86AudioRaiseVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"; }
          XF86AudioLowerVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"; }
          XF86AudioMute         allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
          XF86AudioMicMute      allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
          XF86MonBrightnessUp   allow-when-locked=true { spawn "${brightnessctl}" "--class=backlight" "set" "+10%"; }
          XF86MonBrightnessDown allow-when-locked=true { spawn "${brightnessctl}" "--class=backlight" "set" "10%-"; }
          XF86AudioNext         allow-when-locked=true { spawn "${playerctl}" "next"; }
          XF86AudioPause        allow-when-locked=true { spawn "${playerctl}" "play-pause"; }
          XF86AudioPlay         allow-when-locked=true { spawn "${playerctl}" "play-pause"; }
          XF86AudioPrev         allow-when-locked=true { spawn "${playerctl}" "previous"; }

          Mod+BracketRight { spawn "${wpaperctl}" "next"; }
          Mod+BracketLeft  { spawn "${wpaperctl}" "previous"; }
        }
      '';

      # xresources.properties = {
      #   "Xft.dpi" = 152; # 96 * ~1.6
      #   "Xft.autohint" = 0;
      #   "Xft.lcdfilter" = "lcddefault";
      #   "Xft.hintstyle" = "hintfull";
      #   "Xft.hinting" = 1;
      #   "Xft.antialias" = 1;
      #   "Xft.rgba" = "rgb";
      # };

      xdg.configFile."foot/foot.ini".text = ''
        shell=zellij
        font=${config.system.pretty.theme.fonts.mono.name}:weight=bold:size=12
        font-bold=${config.system.pretty.theme.fonts.mono.name}:weight=bold:size=12
        font-italic=${config.system.pretty.theme.fonts.mono.name}:weight=bold:slant=italic:size=12
        font-bold-italic=${config.system.pretty.theme.fonts.mono.name}:weight=bold:slant=italic:size=12
        dpi-aware=no
        pad=40x30

        [colors]
        regular0=${config.system.pretty.theme.colors.normal.black.hexRGBbase}
        regular1=${config.system.pretty.theme.colors.normal.red.hexRGBbase}
        regular2=${config.system.pretty.theme.colors.normal.green.hexRGBbase}
        regular3=${config.system.pretty.theme.colors.normal.yellow.hexRGBbase}
        regular4=${config.system.pretty.theme.colors.normal.blue.hexRGBbase}
        regular5=${config.system.pretty.theme.colors.normal.magenta.hexRGBbase}
        regular6=${config.system.pretty.theme.colors.normal.cyan.hexRGBbase}
        regular7=${config.system.pretty.theme.colors.normal.white.hexRGBbase}
        bright0=${config.system.pretty.theme.colors.bright.black.hexRGBbase}
        bright1=${config.system.pretty.theme.colors.bright.red.hexRGBbase}
        bright2=${config.system.pretty.theme.colors.bright.green.hexRGBbase}
        bright3=${config.system.pretty.theme.colors.bright.yellow.hexRGBbase}
        bright4=${config.system.pretty.theme.colors.bright.blue.hexRGBbase}
        bright5=${config.system.pretty.theme.colors.bright.magenta.hexRGBbase}
        bright6=${config.system.pretty.theme.colors.bright.cyan.hexRGBbase}
        bright7=${config.system.pretty.theme.colors.bright.white.hexRGBbase}
        background=${config.system.pretty.theme.colors.primary.background.hexRGBbase}
        foreground=${config.system.pretty.theme.colors.primary.foreground.hexRGBbase}
        selection-background=${config.system.pretty.theme.colors.cursor.text.hexRGBbase}
        selection-foreground=${config.system.pretty.theme.colors.cursor.cursor.hexRGBbase}

        alpha=0.9
      '';

      xdg.configFile."wpaperd/config.toml".text = ''
        [default]
        path = "${config.system.user.dirs.config.absolutePath}/wpaperd/rotation"
        duration = "30m"
        sorting = "ascending"
      '';

      # wayland.windowManager.niri = {
      #   enable = true;
      #   xwayland.enable = true;
      #   systemd.enable = false;

      #   settings = {
      #     "$mod" = "SUPER";
      #     "$term" = "${pkgs.foot}/bin/foot";
      #     "$menu" = "${pkgs.tofi}/bin/tofi-run | xargs hyprctl dispatch exec --";
      #     "$wallpaper" = "${pkgs.wpaperd}/bin/wpaperctl";
      #     "$brightness" = "${pkgs.brightnessctl}/bin/brightnessctl";
      #     "$player" = "${pkgs.playerctl}/bin/playerctl";

      #     monitor = ", highres, auto, auto";

      #     env = [
      #       "XCURSOR_SIZE,16"
      #       "HYPRCURSOR_SIZE,16"
      #       # "GDK_SCALE,2"
      #     ];

      #     # test with `nix run nixpkgs#wev`
      #     bind = [
      #       # Exec
      #       "$mod, Return, exec, $term"
      #       "$mod, D, exec, $menu"

      #       # Window
      #       "$mod SHIFT, Q, killactive"
      #       "$mod SHIFT, Space, togglefloating"
      #       "$mod SHIFT, F, fullscreen"

      #       # Wallpaper
      #       "$mod, code:35, exec, $wallpaper next"
      #       "$mod, code:34, exec, $wallpaper previous"

      #       # Workspace
      #       "$mod, 1, workspace, 1"
      #       "$mod, 2, workspace, 2"
      #       "$mod, 3, workspace, 3"
      #       "$mod, 4, workspace, 4"
      #       "$mod, 5, workspace, 5"
      #       "$mod, 6, workspace, 6"
      #       "$mod, 7, workspace, 7"
      #       "$mod, 8, workspace, 8"
      #       "$mod SHIFT, 1, movetoworkspace, 1"
      #       "$mod SHIFT, 2, movetoworkspace, 2"
      #       "$mod SHIFT, 3, movetoworkspace, 3"
      #       "$mod SHIFT, 4, movetoworkspace, 4"
      #       "$mod SHIFT, 5, movetoworkspace, 5"
      #       "$mod SHIFT, 6, movetoworkspace, 6"
      #       "$mod SHIFT, 7, movetoworkspace, 7"
      #       "$mod SHIFT, 8, movetoworkspace, 8"

      #       # System
      #       "$mod SHIFT, M, exit"
      #     ];

      #     bindm = [
      #       "$mod, mouse:272, movewindow"
      #       "$mod, mouse:273, resizewindow"
      #     ];

      #     bindel = [
      #       ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
      #       ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      #       ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      #       ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      #       ",XF86MonBrightnessUp, exec, $brightness -e4 -n2 set 5%+"
      #       ",XF86MonBrightnessDown, exec, $brightness -e4 -n2 set 5%-"
      #     ];

      #     bindl = [
      #       ", XF86AudioNext, exec, $player next"
      #       ", XF86AudioPause, exec, $player play-pause"
      #       ", XF86AudioPlay, exec, $player play-pause"
      #       ", XF86AudioPrev, exec, $player previous"
      #     ];

      #     general = {
      #       gaps_in = 12;
      #       gaps_out = 24;

      #       "col.inactive_border" = "rgba(${config.system.pretty.theme.colors.window.border.hexRGBAbase})";
      #       "col.active_border" = "rgba(${config.system.pretty.theme.colors.window.active_border.hexRGBAbase})";

      #       border_size = 2;

      #       layout = "dwidle";
      #     };

      #     animations = {
      #       enabled = true;

      #       bezier = "move, 0.05, 0.9, 0.1, 1.05";

      #       animation = [
      #         "windowsMove, 1, 7, move"
      #         "windowsIn, 1, 3, default, popin 90%"
      #         "windowsOut, 1, 3, default, popin 90%"
      #         "border, 1, 2, default"
      #         "fade, 1, 3, default"
      #         "workspaces, 1, 3, default"
      #       ];
      #     };

      #     decoration = {
      #       rounding = 12;
      #       rounding_power = 2;

      #       shadow = {
      #         enabled = true;
      #         range = 12;
      #         render_power = 3;
      #         color = "rgba(${config.system.pretty.theme.colors.window.shadow.hexRGBAbase})";
      #       };

      #       blur = {
      #         enabled = true;
      #         size = 16;
      #         passes = 2;

      #         vibrancy = 0.1696;
      #       };
      #     };

      #     input = {
      #       kb_layout = config.system.keyboard.kb_layout;
      #       kb_options = config.system.keyboard.kb_options;

      #       follow_mouse = 1;
      #       sensitivity = 0;

      #       touchpad = {
      #         natural_scroll = false;
      #       };
      #     };

      #     misc = {
      #       disable_niri_logo = true;

      #       mouse_move_enables_dpms = true;
      #       key_press_enables_dpms = true;
      #     };

      #     xwayland = {
      #       force_zero_scaling = true;
      #     };

      #     exec-once = [
      #       "${pkgs.wpaperd}/bin/wpaperd -d"
      #       "${pkgs.waybar}/bin/waybar"
      #     ];
      #   };
      # };
      # programs.hyprlock.enable = true;
      # services.hyprsunset.enable = true;

      programs.waybar = {
        enable = true;
        # {
        #         "layer": "top",
        #         "position": "top",
        #         "reload_style_on_change": true,
        #         "modules-left": ["custom/notification","clock","custom/pacman","tray"],
        #         "modules-center": ["niri/workspaces"],
        #         "modules-right": ["group/expand","bluetooth","network","battery"],

        #         "niri/workspaces": {
        #             "format": "{icon}",
        #             "format-icons": {
        #                 "active": "",
        #                 "default": "",
        #                 "empty": ""
        #             },
        #             "persistent-workspaces": {
        #                 "*": [ 1,2,3,4,5 ]
        #             }
        #         },
        #         "custom/notification": {
        #             "tooltip": false,
        #             "format": "",
        #             "on-click": "swaync-client -t -sw",
        #             "escape": true
        #         },
        #         "clock": {
        #             "format": "{:%I:%M:%S %p} ",
        #             "interval": 1,
        #             "tooltip-format": "<tt>{calendar}</tt>",
        #             "calendar": {
        #                 "format": {
        #                     "today": "<span color='#fAfBfC'><b>{}</b></span>"
        #                 }
        #             },
        #             "actions": {
        #                 "on-click-right": "shift_down",
        #                 "on-click": "shift_up"
        #             }
        #         },
        #         "network": {
        #             "format-wifi": "",
        #             "format-ethernet":"",
        #             "format-disconnected": "",
        #             "tooltip-format-disconnected": "Error",
        #             "tooltip-format-wifi": "{essid} ({signalStrength}%) ",
        #             "tooltip-format-ethernet": "{ifname} 🖧 ",
        #             "on-click": "kitty nmtui"
        #         },
        #         "bluetooth": {
        #             "format-on": "󰂯",
        #             "format-off": "BT-off",
        #             "format-disabled": "󰂲",
        #             "format-connected-battery": "{device_battery_percentage}% 󰂯",
        #             "format-alt": "{device_alias} 󰂯",
        #             "tooltip-format": "{controller_alias}\t{controller_address}\n\n{num_connections} connected",
        #             "tooltip-format-connected": "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}",
        #             "tooltip-format-enumerate-connected": "{device_alias}\n{device_address}",
        #             "tooltip-format-enumerate-connected-battery": "{device_alias}\n{device_address}\n{device_battery_percentage}%",
        #             "on-click-right": "blueman-manager",
        #         },
        #         "battery": {
        #             "interval":30,
        #             "states": {
        #                 "good": 95,
        #                 "warning": 30,
        #                 "critical": 20
        #             },
        #             "format": "{capacity}% {icon}",
        #             "format-charging": "{capacity}% 󰂄",
        #             "format-plugged": "{capacity}% 󰂄 ",
        #             "format-alt": "{time} {icon}",
        #             "format-icons": [
        #                 "󰁻",
        #             "󰁼",
        #             "󰁾",
        #             "󰂀",
        #             "󰂂",
        #             "󰁹"
        #             ],
        #         },
        #         "custom/pacman": {
        #             "format": "󰅢 {}",
        #             "interval": 30,
        #             "exec": "checkupdates | wc -l",
        #             "exec-if": "exit 0",
        #             "on-click": "kitty sh -c 'yay -Syu; echo Done - Press enter to exit; read'; pkill -SIGRTMIN+8 waybar",
        #             "signal": 8,
        #             "tooltip": false,
        #         },
        #         "custom/expand": {
        #             "format": "",
        #             "tooltip": false
        #         },
        #         "custom/endpoint":{
        #             "format": "|",
        #             "tooltip": false
        #         },
        #         "group/expand": {
        #             "orientation": "horizontal",
        #             "drawer": {
        #                 "transition-duration": 600,
        #                 "transition-to-left": true,
        #                 "click-to-reveal": true
        #             },
        #             "modules": ["custom/expand", "custom/colorpicker","cpu","memory","temperature","custom/endpoint"],
        #         },
        #         "custom/colorpicker": {
        #             "format": "{}",
        #             "return-type": "json",
        #             "interval": "once",
        #             "exec": "~/.config/waybar/scripts/colorpicker.sh -j",
        #             "on-click": "~/.config/waybar/scripts/colorpicker.sh",
        #             "signal": 1
        #         },
        #         "cpu": {
        #             "format": "󰻠",
        #             "tooltip": true
        #         },
        #         "memory": {
        #             "format": ""
        #         },
        #         "temperature": {
        #             "critical-threshold": 80,
        #             "format": "",
        #         },
        #         "tray": {
        #             "icon-size": 14,
        #             "spacing": 10
        #         },
      };
    };
  };
}
