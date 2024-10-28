{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.x11.gtk;
in
{
  options.modules.x11.gtk = {
    enable = mkEnableOption "gtk";
  };

  config = mkIf cfg.enable {
    system.user.hm.gtk = {
      enable = true;
      iconTheme.package = pkgs.adwaita-icon-theme;
      iconTheme.name = "Adwaita";
      theme.package = pkgs.paper-gtk-theme;
      theme.name = "Paper";
    };
  };
}
