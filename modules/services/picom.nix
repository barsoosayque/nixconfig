{ config, pkgs, lib, ... }:

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
      backend = "glx";
    };

    system.user.hm.xdg.configFile."picom/picom.conf".text = ''
      wintype: {
        dropdown_menu = { opacity = 1; shadow = false; };
        popup_menu    = { opacity = 1; shadow = false; };
        utility       = { opacity = 1; shadow = false; };
        tooltip = { fade = true; shadow = true; opacity = 1; focus = true; full-shadow = false; };
        dock = { shadow = false; };
        dnd = { shadow = false; };
      };

      unredir-if-possible = false;
      vsync = false;
      no-use-damage = true;
      detect-rounded-corners = true;
      fading = false;

      shadow = true;
      shadow-radius = 20;
      shadow-opacity = 0.6;
      shadow-offset-x = -10;
      shadow-offset-y = -10;
      shadow-exclude = [
        "class_g ?= 'polybar'"
      ];

      blur: {
        method = "dual_kawase";
        strength = 10;
      };
      blur-background-exclude = [
        "name ?= 'slop'",
        "class_g = 'Peek'",
      ];
      blur-background-frame = true;

      animations = (
        {
          triggers = [ "open", "show" ];
          preset = "appear";
          duration = 0.06;
        },
        {
          triggers = [ "close", "hide" ];
          preset = "disappear";
          duration = 0.06;
        }
      );
    '';
  };
}
