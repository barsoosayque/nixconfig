{ config, options, pkgs, pkgsLocal, lib, modulesLib, ... }:

with lib;
let 
  cfg = config.modules.x11.bspwm;
  xrdbBin = "${pkgs.xorg.xrdb}/bin/xrdb";
  xsetrootBin = "${pkgs.xord.xsetroot}/bin/xsetroot";
  wmnameBin = "${pkgs.wmname}/bin/wmname";
  bspcBin = "${pkgs.bspwm}/bin/bspc";
in
{
  options.modules.x11.bspwm = {
    enable = mkEnableOption "bspwm";

    monitors = mkOption {
      type = types.attrs;
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
    homeManager.services.bspwm = {
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

      extraConfig = ''
        ${xsetrootBin} -cursor_name left_ptr
        ${wmnameBin} LG3D
      '';
    };

    events.onReload = [ "${bspcBin} wm -r" ];

    modules.keyboard.bindings = {
      "super + {shift,shift + ctrl} + q" = "${bspcBin} node -{c,k}";
      "super + {_,shift + }{0-9}" = "${bspcBin} {desktop -f, node -d} '{0-9}'";
      "super + shift + {@space,f}" = ''
        if [ -z "$(${bspcBin} query -N -n focused.tiled)" ]; then \
          ${bspcBin} node focused -t tiled; \
        else \
          ${bspcBin} node focused -t {floating,fullscreen}; \
        fi
      '';
    };
  };
}
