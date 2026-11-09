{
  config,
  options,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.graphics.gtk;
in
{
  options.modules.graphics.gtk = {
    enable = mkEnableOption "gtk";
  };

  config = mkIf cfg.enable {
    system.user.hm.gtk = {
      enable = true;
      iconTheme.package = pkgs.zafiro-icons;
      iconTheme.name = "Zafiro-icons-Dark";
      theme.package = pkgs.gruvbox-gtk-theme;
      theme.name = "Gruvbox-Dark";
      gtk4.theme = config.system.user.hm.gtk.theme;
    };
    system.user.hm.qt = {
      enable = true;
      platformTheme.name = "kvantum";
      style.name = "kvantum";
    };
    # Kvantum has no native home-manager option, so point it at Gruvbox and
    # ship the theme files where Kvantum looks for them.
    system.user.hm.xdg.configFile = {
      "Kvantum/kvantum.kvconfig".text = ''
        [General]
        theme=Gruvbox-Dark-Brown
      '';
      "Kvantum/Gruvbox-Dark-Brown".source = "${pkgs.gruvbox-kvantum}/share/Kvantum/Gruvbox-Dark-Brown";
    };
  };
}
