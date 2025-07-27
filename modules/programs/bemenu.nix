{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types attrsets concatStringsSep cli;

  cfg = config.modules.programs.bemenu;
  settings = cli.toGNUCommandLineShell {} rec {
    l = 20;
    fn = "${config.system.pretty.theme.fonts.menu.name} Bold 16";

    bdr = config.system.pretty.theme.colors.window.active_border.hexRGB;
    tb = config.system.pretty.theme.colors.primary.background.hexRGB;
    tf = config.system.pretty.theme.colors.bright.yellow.hexRGB;
    fb = config.system.pretty.theme.colors.normal.black.hexRGB;
    ff = config.system.pretty.theme.colors.normal.blue.hexRGB;
    hb = config.system.pretty.theme.colors.bright.blue.hexRGB;
    hf = config.system.pretty.theme.colors.primary.background.hexRGB;
    nb = config.system.pretty.theme.colors.primary.background.hexRGB;
    nf = config.system.pretty.theme.colors.primary.foreground.hexRGB;
    ab = config.system.pretty.theme.colors.normal.black.hexRGB;
    af = config.system.pretty.theme.colors.normal.white.hexRGB;
    cf = fb;
    cb = cf;
    line-height = 40;
     
    ignorecase = true;
    counter = true;
    center = true;
    width-factor = 0.66;
    margin = 60;
    border = 4;
    border-radius = 10;
  };
in
{
  options.modules.programs.bemenu = {
    enable = mkEnableOption "bemenu";

    enableEmoji = mkOption {
      type = with types; bool;
      default = true;
      description = "Enable bemenu emoji picker";
    };
  };

  config = mkIf cfg.enable {
    system.keyboard.bindings = {
      "super + d" = "${pkgs.bemenu}/bin/bemenu-run ${settings} -p '  Run:'";
    } // attrsets.optionalAttrs cfg.enableEmoji {
      "super + e" = concatStringsSep " " [
        ''BEMOJI_PICKER_CMD="${pkgs.bemenu}/bin/bemenu ${settings} -p '󰞅  Emoji:'"''
        ''BEMOJI_TYPE_CMD="${pkgs.xdotool}/bin/xdotool type"''
        "${pkgs.bemoji}/bin/bemoji -t -c -n"
      ];
    };
  };
}
