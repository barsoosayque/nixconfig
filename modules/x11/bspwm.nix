{ config, options, pkgs, lib, modulesLib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;
  inherit (pkgs) writeScript;
  inherit (builtins) mapAttrs;

  cfg = config.modules.x11.bspwm;
  xrdbBin = "${pkgs.xorg.xrdb}/bin/xrdb";
  xsetrootBin = "${pkgs.xorg.xsetroot}/bin/xsetroot";
  wmnameBin = "${pkgs.wmname}/bin/wmname";
  bspcBin = "${pkgs.bspwm}/bin/bspc";
in
{
  options.modules.x11.bspwm = {
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

      monitors = mapAttrs (_: l: map toString l) cfg.monitors;

      settings = {
        focused_border_color = "$(${xrdbBin} -query | grep color10 | awk '{print$2}')";
        normal_border_color = "$(${xrdbBin} -query | grep color8 | awk '{print$2}')";
        border_width = 1;
        window_gap = 12;
        split_ratio = 0.5;
        borderless_monocle = true;
        gapless_monocle = true;
        ignore_ewmh_focus = true;
      };

      startupPrograms = [
        "${xsetrootBin} -cursor_name left_ptr"
        "${wmnameBin} LG3D"
      ];
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
      };
  };
}
