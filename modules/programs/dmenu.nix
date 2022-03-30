{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;
  inherit (builtins) concatStringsSep;
  inherit (pkgs) fetchurl;

  cfg = config.modules.programs.dmenu;

  patches = [
    # fuzzymatch
    (fetchurl {
      url = "https://tools.suckless.org/dmenu/patches/fuzzymatch/dmenu-fuzzymatch-4.9.diff";
      sha256 = "d9a1e759cd518348fc37c2c83fbd097232098562ebfd1edf85b51413ff524b79";
    })
    # fuzzymatch highlight
    (fetchurl {
      url = "https://tools.suckless.org/dmenu/patches/fuzzyhighlight/dmenu-fuzzyhighlight-4.9.diff";
      sha256 = "82cbcc1a6a721fb670f6561b98a58e8a2301bffde2e94c87e77868b09927aa57";
    })
    # numbers
    (fetchurl {
      url = "https://tools.suckless.org/dmenu/patches/numbers/dmenu-numbers-4.9.diff";
      sha256 = "f79de21544b83fa1e86f0aed5e849b1922ebae8d822e492fbc9066c0f07ddb69";
    })
    # mouse support
    (fetchurl {
      url = "https://tools.suckless.org/dmenu/patches/mouse-support/dmenu-mousesupport-5.0.diff";
      sha256 = "690daaf24d4379f9ed4dbc1d7f7864a86fada420afc6ef792d9e2d09bd6fe8b6";
    })
  ];

  params = concatStringsSep " " [
    "-l 10"
    "-fn '${cfg.font.name}'"
    # background colors
    "-nb '${config.system.pretty.theme.colors.primary.background}'"
    "-sb '${config.system.pretty.theme.colors.cursor.accent}'"
    "-nhb '${config.system.pretty.theme.colors.primary.background}'"
    "-shb '${config.system.pretty.theme.colors.cursor.accent}'"
    # foreground colors
    "-nf '${config.system.pretty.theme.colors.cursor.cursor}'"
    "-sf '${config.system.pretty.theme.colors.cursor.text}'"
    "-nhf '${config.system.pretty.theme.colors.cursor.accent}'"
    "-shf '${config.system.pretty.theme.colors.cursor.text}'"
  ];
in
{
  options.modules.programs.dmenu = {
    enable = mkEnableOption "dmenu";

    enableEmoji = mkOption {
      type = with types; bool;
      default = true;
      description = "Enable dmenu emoji picker";
    };

    font = {
      package = mkOption {
        type = with types; package;
        default = pkgs.ubuntu_font_family;
        description = "Font nix package";
      };

      name = mkOption {
        type = with types; str;
        default = "Ubuntu:Bold";
        description = "Font name according to the package";
      };
    };
  };

  config = mkIf cfg.enable {
    fonts.fonts = [ cfg.font.package ];

    nixpkgs.overlays = [
      (self: super: {
        dmenu = super.dmenu.override { inherit patches; };
      })
    ];

    system.keyboard.bindings = {
      "super + d" = "${pkgs.dmenu}/bin/dmenu_run ${params} -p \"Run: \"";
    };
    # todo dmenu_emoji
    #// attrsets.optionalAttrs cfg.enableEmoji {
    # "super + e" = "${pkgsLocal.dmenu_emoji}/bin/dmenu_emoji ${params} -p \"Emoji: \"";
    # };
  };
}
