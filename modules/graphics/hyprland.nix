{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types lists attrsets;
  
  cfg = config.modules.graphics.hyprland;
in
{
  options.modules.graphics.hyprland = {
    enable = mkEnableOption "hyprland";
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
    programs.hyprlock.enable = true;

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayloand";
      XDG_SESSION_TYPE = "wayland";
    };
  };
}
