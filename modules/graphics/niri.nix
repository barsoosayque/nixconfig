{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;
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
      pkgs.phinger-cursors
      # pkgs.xorg.xrdb
    ];

    programs.niri = {
      enable = true;
      useNautilus = true;
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${config.programs.niri.package}/bin/niri-session";
          user = config.system.user.name;
        };
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
        // spawn-at-startup "${pkgs.waybar}/bin/waybar"
        spawn-at-startup "bash" "-c" "${pkgs.wpaperd}/bin/wpaperd -d"
        spawn-at-startup "${config.system.events.onWMLoadedScript}"

        prefer-no-csd

        xwayland-satellite {
          path "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
        }

        environment {
          _JAVA_AWT_WM_NONREPARENTING "1"
          ELECTRON_OZONE_PLATFORM_HINT "auto"
          DISPLAY ":0"
        }

        hotkey-overlay {
          skip-at-startup
        }

        layout {
          gaps 20
          struts {
            left 00
            right 00
            top 00
            bottom 00
          }
          always-center-single-column
          // center-focused-column "on-overflow"
          default-column-display "tabbed"
          tab-indicator {
            hide-when-single-tab
            width 8
            gap 8
            length total-proportion=1.0
            position "top"
            place-within-column
          }
          default-column-width { proportion 0.8; }
          focus-ring {
            width 1;
            inactive-color "${config.system.pretty.theme.colors.window.border.hexRGBA}";
            active-color   "${config.system.pretty.theme.colors.window.active_border.hexRGBA}";
            urgent-color   "${config.system.pretty.theme.colors.window.urgent_border.hexRGBA}";
          }
          shadow {
            on
            softness 25;
            spread 0;
            offset x=0 y=0;
            draw-behind-window false;
            color "${config.system.pretty.theme.colors.window.shadow.hexRGBA}";
          }
          insert-hint {
            color "${config.system.pretty.theme.colors.cursor.accent.hexRGB}80";
          }
        }

        window-rule {
          geometry-corner-radius 2
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

        cursor {
            xcursor-theme "phinger-cursors-light"
            xcursor-size 24
        }

        output "eDP-1" {
            // off
            mode "2560x1600@165.02"
            scale 1.25
            focus-at-startup
        }

        gestures {
            hot-corners {
                off
            }
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
          Mod+S { spawn "${pkgs.wayshot}/bin/wayshot" "--clipboard" "--cursor"; }

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

          Mod+Shift+Left  { move-column-left; }
          Mod+Shift+Down  { move-window-down; }
          Mod+Shift+Up    { move-window-up; }
          Mod+Shift+Right { move-column-right; }
          Mod+Shift+H     { move-column-left; }
          Mod+Shift+J     { move-window-down; }
          Mod+Shift+K     { move-window-up; }
          Mod+Shift+L     { move-column-right; }

          Mod+Ctrl+H { set-column-width "-10%"; }
          Mod+Ctrl+L { set-column-width "+10%"; }
          Mod+Ctrl+J { set-window-height "-10%"; }
          Mod+Ctrl+K { set-window-height "+10%"; }

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

      xdg.configFile."wpaperd/config.toml".text = ''
        [default]
        path = "${config.system.user.dirs.config.absolutePath}/wpaperd/rotation"
        duration = "10m"
        sorting = "random"
      '';
    };
  };
}
