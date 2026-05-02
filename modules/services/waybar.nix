{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.services.waybar;
in
{
  options.modules.services.waybar = {
    enable = mkEnableOption "waybar";
  };

  config = mkIf cfg.enable {
    system.events.onWMLoaded = [ "${pkgs.waybar}/bin/waybar" ];

    system.user.hm.programs.waybar = {
      enable = true;
      # systemd.enable = true;

      settings = {
        mainBar = {
          reload_style_on_change = true;
          layer = "top";
          position = "top";
          # height = 0;
          spacing = 0;
          monitor = [ "$WAYBAR_DISPLAY" ];

          fixed-center = true;
          modules-left = [
            "niri/language"
            "niri/workspaces"
            "tray"
          ];
          modules-center = [ "clock" ];
          modules-right = [
            "network"
            "battery"
            "bluetooth"
            "pulseaudio"
            "backlight"
            "memory"
            "cpu"
          ];

          tooltip = true;

          "niri/language" = {
            format = "󰌌  {short}";
          };

          "niri/workspaces" = {
            disable-scroll = false;
            hide-empty = true;
            all-outputs = true;
            format = "{icon}";
            format-icons = {
              "scratch" = "";
              "work" = "󱃖";
              "web" = "";
              "chat" = "";
              "default" = "";
            };
          };

          "network" = rec {
            format-wifi = "   {signalStrength}%";
            format-ethernet = "󰈀   Wired";
            format-linked = "󱘖   {ifname} (No IP)";
            format-disconnected = "󰊠   {ifname}";
            interval = 1;
            tooltip-format-bytes = "󰅧   {bandwidthUpBytes}   󰅢   {bandwidthDownBytes}\n󰩟   {ipaddr}";
            tooltip-format-wifi = "   {essid} ({signalStrength}%)\n${tooltip-format-bytes}";
            tooltip-format-ethernet = "   {ifname}\n${tooltip-format-bytes}";
            tooltip-format-disconnected = "Disconnected\n${tooltip-format-bytes}";
          };

          "battery" = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = "󱐋 {capacity}%";
            interval = 1;
            format-icons = [
              "󰂎"
              "󰁼"
              "󰁿"
              "󰂁"
              "󰁹"
            ];
            tooltip = true;
          };

          "bluetooth" = {
            format = "󰂯 {status}";
            format-connected = "󰂯 {num_connections}";
            tooltip-format = "{controller_alias}\n{controller_address}\n\n{num_connections} connected";
            tooltip-format-connected = "{controller_alias}\n{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
            tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
            on-click-right = "${pkgs.blueman}/bin/blueman-manager";
          };

          "pulseaudio" = {
            format = "{icon}   {volume}%";
            format-muted = "   muted";
            format-icons = {
              default = [
                ""
                ""
                ""
              ];
            };
            on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
            on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          };

          "backlight" = {
            device = "intel_backlight";
            format = "{icon}  {percent}%";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
              ""
              ""
            ];
          };

          "memory" = {
            format = "󰢑  {percentage}%";
            tooltip = true;
            tooltip-format = "{used:0.2f}G/{total:0.2f}G";
          };

          "cpu" = {
            format = "  {usage}%";
            tooltip = true;
          };

          "clock" = {
            interval = 1;
            format = "󰥔  {:%H:%M     %d.%m.%Y, %A}";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              format = {
                months = "<span color='${config.system.pretty.theme.colors.normal.yellow.hexRGB}'><b>{}</b></span>";
                days = "<span color='${config.system.pretty.theme.colors.normal.magenta.hexRGB}'><b>{}</b></span>";
                weeks = "<span color='${config.system.pretty.theme.colors.normal.cyan.hexRGB}'><b>W{}</b></span>";
                weekdays = "<span color='${config.system.pretty.theme.colors.bright.yellow.hexRGB}'><b>{}</b></span>";
                today = "<span color='${config.system.pretty.theme.colors.normal.red.hexRGB}'><b><u>{}</u></b></span>";
              };
            };
          };

          "tray" = {
            icon-size = 16;
            spacing = 8;
          };
        };
      };

      style = ''
        * {
          font-family: "${config.system.pretty.theme.fonts.bar.name}";
          font-weight: 400;
          font-size: 16px;
        }

        #waybar {
          background-color: transparent;
          border: none;
          box-shadow: none;
        }

        #waybar > * {
          margin-top: 10px;
        }

        #clock {
          font-style: italic;
        }
        tooltip {
          background-color: ${config.system.pretty.theme.colors.bar.background.cssRgba};
        }
        tooltip label, #waybar {
          color: ${config.system.pretty.theme.colors.bar.foreground.cssRgba};
        }

        #workspaces,
        #window,
        #tray,
        #clock,
        #language,
        #network,
        #bluetooth,
        #battery,
        #pulseaudio,
        #backlight,
        #memory,
        #cpu {
          border-radius: 15px;
          background-color: ${config.system.pretty.theme.colors.bar.background.cssRgba};
          padding: 2px 15px;
        }

        #network:hover,
        #battery:hover,
        #bluetooth:hover,
        #pulseaudio:hover,
        #backlight:hover,
        #memory:hover,
        #cpu:hover,
        #clock:hover {
          background-color: ${config.system.pretty.theme.colors.bar.backgroundHover.cssRgba};
          color: ${config.system.pretty.theme.colors.bar.foregroundHover.cssRgba};
        }

        #language {
          margin-left: 20px;
          margin-right: 10px;
        }
        #tray {
          margin-left: 10px;
        }
        #cpu {
          margin-right: 20px;
        }

        #workspaces button.active {
          color: ${config.system.pretty.theme.colors.bar.accent.cssRgba};
          padding: 2px 8px;
          margin: 0 2px;
        }

        #workspaces button {
          border: none;
          background: none;
          box-shadow: none;
          color: ${config.system.pretty.theme.colors.bar.foreground.cssRgba};
          padding: 2px 8px;
          margin: 0 2px;
        }

        #workspaces button:hover {
          border: none;
          background: none;
          box-shadow: none;
          text-shadow: none;
          -gtk-icon-shadow: none;
          -gtk-icon-effect: none;
          transition: none;
          color: ${config.system.pretty.theme.colors.bar.foregroundHover.cssRgba};
        }

        #network {
          border-radius: 15px 0 0 15px;
        }
        #battery, #bluetooth, #pulseaudio, #backlight, #memory {
          border-radius: 0;
        }
        #cpu{
          border-radius: 0 15px 15px 0;
        }
      '';
    };
  };
}
