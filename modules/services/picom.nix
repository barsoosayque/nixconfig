{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.services.picom;
in
{
  options.modules.services.picom = {
    enable = mkEnableOption "picom";
  };

  config = mkIf cfg.enable {
    system.user.hm.services.picom = {
      enable = true;
      settings = {
        blur = {
          method = "dual_kawase";
          strength = 10;
          # kern = "7x7box";
        };
        blur-background-exclude = [
          "name ?= 'slop'"
          "class_g = 'Peek'"
        ];
        # shadow = true;

        backend = "glx";
        # round-borders = 1;
        # corner-radius = 15;

        unredir-if-possible = false;
        vsync = true;
        no-use-damage = true;
        # xrender-sync-fence = true;
        # vsync-use-glfinish = true;
        # mark-wmwin-focused = true;
        # mark-ovredir-focused = true;
        # detect-client-opacity = true;
        # detect-rounded-corners = true;
      };
    };
  };
}
