{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;
  inherit (builtins) concatStringsSep;
  inherit (pkgs) fetchurl;

  cfg = config.modules.programs.dmenu;

  patches = [
    # fuzzymatch
    # (fetchurl {
    #   url = "https://tools.suckless.org/dmenu/patches/fuzzymatch/dmenu-fuzzymatch-4.9.diff";
    #   sha256 = "d9a1e759cd518348fc37c2c83fbd097232098562ebfd1edf85b51413ff524b79";
    # })
    # fuzzymatch highlight (borked)
    # (fetchurl {
    #   url = "https://tools.suckless.org/dmenu/patches/fuzzyhighlight/dmenu-fuzzyhighlight-4.9.diff";
    #   sha256 = "82cbcc1a6a721fb670f6561b98a58e8a2301bffde2e94c87e77868b09927aa57";
    # })
    # numbers
    # (fetchurl {
    #   url = "https://tools.suckless.org/dmenu/patches/numbers/dmenu-numbers-20220512-28fb3e2.diff";
    #   sha256 = "sha256-dXAmbub13PUDjygoxsK0PNnCPc5yNWOIPtrNLvy8fSw=";
    # })
    # mouse support
    # (fetchurl {
    #   url = "https://tools.suckless.org/dmenu/patches/mouse-support/dmenu-mousesupport-5.3.diff";
    #   sha256 = "sha256-Gt7PSGOjZnI07I7Y4ec1DJRjKcbw/uVqAB+imPTU4s0=";
    # })
  ];

  params = concatStringsSep " " [
    "-l 10"
    "-fn '${cfg.font.name}'"
    # background colors
    "-nb '${config.system.pretty.theme.colors.primary.background.hexRGB}'"
    "-sb '${config.system.pretty.theme.colors.cursor.accent.hexRGB}'"
    # "-nhb '${config.system.pretty.theme.colors.primary.background.hexRGB}'"
    # "-shb '${config.system.pretty.theme.colors.cursor.accent.hexRGB}'"
    # foreground colors
    "-nf '${config.system.pretty.theme.colors.cursor.cursor.hexRGB}'"
    "-sf '${config.system.pretty.theme.colors.cursor.text.hexRGB}'"
    # "-nhf '${config.system.pretty.theme.colors.cursor.accent.hexRGB}'"
    # "-shf '${config.system.pretty.theme.colors.cursor.text.hexRGB}'"
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
    fonts.packages = [ cfg.font.package ];

    nixpkgs.overlays = [
      (self: super: {
        dmenu = super.dmenu.override { inherit patches; };
      })
    ];
    
    environment.systemPackages = [ pkgs.dmenu ];

    system.keyboard.bindings = {
      "super + d" = "${pkgs.dmenu}/bin/dmenu_run ${params} -p \"Run: \"";
    };
    # todo dmenu_emoji
    #// attrsets.optionalAttrs cfg.enableEmoji {
    # "super + e" = "${pkgsLocal.dmenu_emoji}/bin/dmenu_emoji ${params} -p \"Emoji: \"";
    # };
  };
}
