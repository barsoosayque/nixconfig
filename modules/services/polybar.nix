{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  xrandrBin = "${pkgs.xorg.xrandr}/bin/xrandr";
  grepBin = "${pkgs.gnugrep}/bin/grep";
  cutBin = "${pkgs.coreutils}/bin/cut";

  cfg = config.modules.services.polybar;
  script = ''
    pkill polybar
    for m in $(${xrandrBin} --query | ${grepBin} " connected" | ${cutBin} -d" " -f1); do \
      MONITOR=$m polybar --reload main & \
    done
  '';
in
{
  options.modules.services.polybar = {
    enable = mkEnableOption "polybar";
  };

  config = mkIf cfg.enable {
    system.events.onWMLoaded = [ script ];
    system.events.onReload = [ script ];

    system.user.hm.services.polybar = {
      enable = true;
      script = ""; # using custom events to load/reload polybar
      package = pkgs.polybar.override {
        pulseSupport = true;
      };
      settings = {
        "bar/main" = {
          monitor = "\${env:MONITOR:}";
          width = "100%";
          height = "30px";
          module-margin = "15px";
          padding = "20px";
          # bottom = true;
          # override-redirect = false;
          fixed-center = true;
          modules-left = "keyboard time date bspwm";
          modules-center = "";
          modules-right = "battery backlight pulse cpu ram tray";
          wm-restack = "bspwm";
          separator = "";
          dpi = "";
          font = [ "${config.system.pretty.theme.fonts.bar.name}:style=Bold:size=11;3" ];
          border-color = config.system.pretty.theme.colors.bar.background.hexARGB;
          background = config.system.pretty.theme.colors.bar.background.hexARGB;
          foreground = config.system.pretty.theme.colors.bar.foreground.hexARGB;
        };

        "module/bspwm" = {
          type = "internal/bspwm";

          label-separator = " ";
          label-empty = " ";
          label-occupied  = " ";
          label-focused = " ";
          label-urgent = "󰗖 ";

          label-urgent-foreground = config.system.pretty.theme.colors.bar.danger.hexARGB;
        };

        "module/cpu" = {
          type = "internal/cpu";

          format = "  <label>";
          format-warn = "  <label-warn>";
        };

        "module/keyboard" = {
          type = "internal/xkeyboard";
        };

        "module/ram" = {
          type = "internal/memory";

          format = " <label>";
          label = "%percentage_used%%";
        };

        "module/net" = {
          type = "internal/network";

          interface-type = "wired";
          # speed-unit = "";

          format-connected = "   <label-connected>";
          label-connected = " %downspeed%   %upspeed%";
          format-disconnected = "   <label-disconnected>";
          label-disconnected = "no connection";
          format-packetloss = "   <label-packetloss>";
          label-packetloss = "packet loss";
        };

        "module/time" = {
          type = "internal/date";
          interval = 1;
          format = "<label>";
          time = "%R %p";
          label = "%time%";
        };

        "module/date" = {
          type = "internal/date";
          interval = 60;
          format = "<label>";
          date = "%d %B %Y";
          label = "%date%";
        };

        "module/battery" = {
          type = "internal/battery";
          full-at = 95;
          low-at = 15;
          battery = "BAT0";
          adapter = "AC";
          poll-interval = 5;
          time-format = "%H:%M";

          format-charging = "<animation-charging> <label-charging>";
          label-charging = "%percentage%%";
          animation-charging-0 = " ";
          animation-charging-1 = " ";
          animation-charging-2 = " ";
          animation-charging-3 = " ";
          animation-charging-4 = " ";
          animation-charging-framerate = "750";

          format-discharging = "<ramp-capacity> <label-discharging>";
          label-discharging = "%percentage%%";
          animation-discharging-0 = " ";
          animation-discharging-1 = " ";
          animation-discharging-2 = " ";
          animation-discharging-3 = " ";
          animation-discharging-4 = " ";
          animation-discharging-framerate = "500";

          format-full = "<ramp-capacity> <label-full>";
          label-full = "full";
          ramp-capacity-0 = " ";
          ramp-capacity-1 = " ";
          ramp-capacity-2 = " ";
          ramp-capacity-3 = " ";
          ramp-capacity-4 = " ";

          format-low = "  <label-low> <animation-low>";
          label-low = "%percentage%%";
          animation-low-0 = "";
          animation-low-1 = "";
          animation-low-framerate = "200";
        };

        "module/backlight" = {
          type = "internal/backlight";
          enable-scroll = false;
          format = "<ramp> <label>";
          label = "%percentage%%";
          ramp-0 = "󰛩";
          ramp-1 = "󱩐";
          ramp-2 = "󱩓";
          ramp-3 = "󱩕";
          ramp-4 = "󰛨";
        };

        "module/pulse" = {
          type = "internal/pulseaudio";
          use-ui-max = "true";
          interval = 5;
          reverse-scroll = "true";
          click-right = "pavucontrol";

          format-volume = "<ramp-volume> <label-volume>";
          label-volume = "%percentage%%";
          ramp-volume-0 = "";
          ramp-volume-1 = "";
          ramp-volume-2 = " ";

          format-muted = "<label-muted>";
          label-muted = "  off";
          # label-muted-foreground = "#666";
        };

        "module/tray" = {
          type = "internal/tray";
          tray-size = "55%";
          tray-spacing = "5px";
          # format-margin = "8px";
        };
      };
    };
  };
}
