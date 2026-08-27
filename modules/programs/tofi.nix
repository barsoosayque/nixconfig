{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types attrsets cli ;
  inherit (pkgs) writeShellScript;

  cfg = config.modules.programs.tofi;
  settings = cli.toCommandLineShellGNU { } {
    font = "${config.system.pretty.theme.fonts.menu.name} Bold";
    font-size = 14;

    width = "100%";
    height = "100%";

    border-width = 0;
    outline-width = 0;

    padding-left = "35%";
    padding-right = "35%";
    padding-top = "20%";
    padding-bottom = "20%";

    result-spacing = 4;
    num-results = 0;

    background-color = (config.system.pretty.theme.colors.primary.background.modify { a = 220; }).hexRGBAbase;
    text-color = config.system.pretty.theme.colors.primary.foreground.hexRGBAbase;
    prompt-color = config.system.pretty.theme.colors.bright.yellow.hexRGBAbase;
    input-color = config.system.pretty.theme.colors.normal.blue.hexRGBAbase;

    selection-color = config.system.pretty.theme.colors.primary.background.hexRGBAbase;
    selection-background = config.system.pretty.theme.colors.bright.blue.hexRGBAbase;
    selection-match-color = config.system.pretty.theme.colors.normal.black.hexRGBAbase;
  };
in
{
  options.modules.programs.tofi = {
    enable = mkEnableOption "tofi";

    enableEmoji = mkOption {
      type = with types; bool;
      default = true;
      description = "Enable tofi emoji picker";
    };

    args = mkOption {
      type = with types; str;
      readOnly = true;
      description = "Themed tofi CLI arguments, for other modules to reuse for a consistent look";
    };
  };

  config = {
    modules.programs.tofi.args = settings;

    system.keyboard.bindings = mkIf cfg.enable ({
      "super + d" = writeShellScript "run-tofi" ''
        selection=$(eval "${pkgs.tofi}/bin/tofi-run ${settings} --prompt-text '  Run: '")
        [ -n "$selection" ] && exec $selection
      '';
    }
    // attrsets.optionalAttrs cfg.enableEmoji {
      "super + e" = writeShellScript "run-tofi-emoji" ''
        export BEMOJI_PICKER_CMD="${pkgs.tofi}/bin/tofi ${settings} --prompt-text '󰞅  Emoji: '"
        export BEMOJI_TYPE_CMD="${pkgs.wtype}/bin/wtype -s 30"
        ${pkgs.bemoji}/bin/bemoji -t -c -n
      '';
    });
  };
}
