{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.programs.foot;
  pkg = pkgs.foot;
in
{
  options.modules.programs.foot = {
    enable = mkEnableOption "foot";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkg ];

    system.keyboard.bindings = {
      "super + Return" = "${pkg}/bin/foot";
    };

    programs.foot = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        main = {
          shell = "zellij";
          font = "${config.system.pretty.theme.fonts.mono.name}:weight=400:size=13";
          font-bold = "${config.system.pretty.theme.fonts.mono.name}:weight=bold:size=13";
          font-italic = "${config.system.pretty.theme.fonts.mono.name}:weight=400:slant=italic:size=13";
          font-bold-italic = "${config.system.pretty.theme.fonts.mono.name}:weight=bold:slant=italic:size=13";
          dpi-aware = "no";
          pad = "20x20";
        };
        colors = {
          regular0 = "${config.system.pretty.theme.colors.normal.black.hexRGBbase}";
          regular1 = "${config.system.pretty.theme.colors.normal.red.hexRGBbase}";
          regular2 = "${config.system.pretty.theme.colors.normal.green.hexRGBbase}";
          regular3 = "${config.system.pretty.theme.colors.normal.yellow.hexRGBbase}";
          regular4 = "${config.system.pretty.theme.colors.normal.blue.hexRGBbase}";
          regular5 = "${config.system.pretty.theme.colors.normal.magenta.hexRGBbase}";
          regular6 = "${config.system.pretty.theme.colors.normal.cyan.hexRGBbase}";
          regular7 = "${config.system.pretty.theme.colors.normal.white.hexRGBbase}";
          bright0 = "${config.system.pretty.theme.colors.bright.black.hexRGBbase}";
          bright1 = "${config.system.pretty.theme.colors.bright.red.hexRGBbase}";
          bright2 = "${config.system.pretty.theme.colors.bright.green.hexRGBbase}";
          bright3 = "${config.system.pretty.theme.colors.bright.yellow.hexRGBbase}";
          bright4 = "${config.system.pretty.theme.colors.bright.blue.hexRGBbase}";
          bright5 = "${config.system.pretty.theme.colors.bright.magenta.hexRGBbase}";
          bright6 = "${config.system.pretty.theme.colors.bright.cyan.hexRGBbase}";
          bright7 = "${config.system.pretty.theme.colors.bright.white.hexRGBbase}";
          background = "${config.system.pretty.theme.colors.primary.background.hexRGBbase}";
          foreground = "${config.system.pretty.theme.colors.primary.foreground.hexRGBbase}";
          selection-background = "${config.system.pretty.theme.colors.cursor.text.hexRGBbase}";
          selection-foreground = "${config.system.pretty.theme.colors.cursor.cursor.hexRGBbase}";
          alpha = 0.95;
        };
      };
    };
  };
}
