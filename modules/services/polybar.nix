{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  xrandrBin = "${pkgs.xorg.xrandr}/bin/xrandr";
  grepBin = "${pkgs.gnugrep}/bin/grep";
  cutBin = "${pkgs.coreutils}/bin/cut";

  cfg = config.modules.services.polybar;
in
{
  options.modules.services.polybar = {
    enable = mkEnableOption "polybar";
  };

  config = mkIf cfg.enable {
    system.user.hm.services.polybar = {
      enable = true;
      script = ''
        for m in $(${xrandrBin} --query | ${grepBin} " connected" | ${cutBin} -d" " -f1); do \
          MONITOR=$m polybar --reload main & \
        done
      '';
      settings = {
        "bar/main" = {
          monitor = "\${env:MONITOR:}";
          width = "100%";
          height = "30px";
          bottom = true;
          # override-redirect = false;
          fixed-center = true;
          padding = "20px";
          modules-left = "cpu ram";
          modules-center = "time date";
          modules-right = "bspwm";
          module-margin = "20px";
          wm-restack = "bspwm";
          separator = "~";
          font = [ "Iosevka Nerd Font:style=Medium,size=13;3" ];
          border-color = config.system.pretty.theme.colors.bar.background.hexARGB;
          background = config.system.pretty.theme.colors.bar.background.hexARGB;
          foreground = config.system.pretty.theme.colors.bar.foreground.hexARGB;
        };

        "module/bspwm" = {
          type = "internal/bspwm";

          label-separator = "  ";
          label-empty = "";
          label-occupied  = "";
          label-focused = "";
          label-urgent = "";

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

          format = " <label>";
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
      };
    };
  };
}
