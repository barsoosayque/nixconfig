{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let 
  cfg = config.modules.x11.gtk;
in
{
  options.modules.x11.gtk = {
    enable = mkEnableOption "gtk";
  };

  config = mkIf cfg.enable {
    homeManager.programs.gtk = {
      enable = true;
      iconTheme.package = pkgs.gnome3.adwaita-icon-theme;
      iconTheme.name = "Paper";
      theme.package = pkgs.paper-gtk-theme;
      theme.name = "Paper";
    };
  };
}
