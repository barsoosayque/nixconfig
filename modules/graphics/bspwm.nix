{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;
  inherit (pkgs) writeScript;
  inherit (builtins) mapAttrs;

  cfg = config.modules.graphics.bspwm;
  xsetrootBin = "${pkgs.xorg.xsetroot}/bin/xsetroot";
  wmnameBin = "${pkgs.wmname}/bin/wmname";
  bspcBin = "${pkgs.bspwm}/bin/bspc";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
in
{
  options.modules.graphics.bspwm = {
    enable = mkEnableOption "bspwm";

    monitors = mkOption {
      type = with types; attrs;
      description = ''
        List of monitor identifiers (use xrandr) with workspaces.
        {
          "DVI-0" = [ 1 2 3 4 0 ];
          "DVI-1" = [ 5 6 7 8 9 ];
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    system.user.hm.xsession.windowManager.bspwm = {
      enable = true;

      package = pkgs.bspwm.overrideAttrs (_: {
        patches = [ ./patches/bspwm-rounded.patch ];
      });

      monitors = mapAttrs (_: l: map toString l) cfg.monitors;

      settings = {
        focused_border_color = config.system.pretty.theme.colors.window.active_border.hexRGB;
        normal_border_color = config.system.pretty.theme.colors.window.border.hexRGB;
        urgent_border_color = config.system.pretty.theme.colors.window.urgent_border.hexRGB;
        border_width = 4;
        border_radius = 20;
        top_padding = 30;
        bottom_padding = 30;
        left_padding = 30;
        right_padding = 30;
        window_gap = 20;
        split_ratio = 0.5;
        borderless_monocle = true;
        gapless_monocle = true;
        ignore_ewmh_focus = true;

        focus_follows_pointer = false;
        history_aware_focus = true;
        focus_by_distance = true;
      };

      startupPrograms = [
        "${xsetrootBin} -cursor_name left_ptr"
        "${wmnameBin} LG3D"
        "${config.system.events.onWMLoadedScript}"
      ];

      rules = {
        mpv = {
          state = "floating";
        };
      };
    };

    system.events.onReload = [ "${bspcBin} wm -r" ];

    system.keyboard.bindings =
      let
        bspcToggleMode = mode: toString (writeScript "bspwm-toggle-${mode}"
          ''
            MODE="${mode}";

            if [ -z $(${bspcBin} query -N -n focused.tiled) ]; then
              MODE="tiled";
            fi

            ${bspcBin} node focused -t $MODE
          '');
      in
      {
        "super + {shift,shift + ctrl} + q" = "${bspcBin} node -{c,k}";
        "super + {_,shift + }{0-9}" = "${bspcBin} {desktop -f, node -d} '{0-9}'";
        "super + shift + space" = bspcToggleMode "floating";
        "super + shift + f" = bspcToggleMode "fullscreen";
        "XF86AudioRaiseVolume" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
        "XF86AudioLowerVolume" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
        "XF86AudioMute" = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "XF86AudioMicMute" = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        "XF86MonBrightnessUp" = "${brightnessctl} --class=backlight set +10%";
        "XF86MonBrightnessDown" = "${brightnessctl} --class=backlight set 10%-";
        "XF86AudioNext" = "${playerctl} next";
        "XF86AudioPause" = "${playerctl} play-pause";
        "XF86AudioPlay" = "${playerctl} play-pause";
        "XF86AudioPrev" = "${playerctl} previous";
      };
  };
}
