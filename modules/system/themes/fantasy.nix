{ localLib, ... }:

let
  inherit (localLib.colorUtils) mkColorHex;
in
{
  # Fonts
  fonts = {
    primary = {
      name = "Iosevka Nerd Font";
      package = pkgs.nerd-fonts.iosevka;
    };
  };

  # General colorscheme: Base16 Material Palenight 256
  colors = rec {
    normal = {
      black = mkColorHex "#292d3e";
      red = mkColorHex "#f07178";
      green = mkColorHex "#c3e88d";
      yellow = mkColorHex "#ffcb6b";
      blue = mkColorHex "#82aaff";
      magenta = mkColorHex "#c792ea";
      cyan = mkColorHex "#89ddff";
      white = mkColorHex "#959dcb";
    };

    bright = {
      black = mkColorHex "#676e95";
      red = mkColorHex "#f07178";
      green = mkColorHex "#c3e88d";
      yellow = mkColorHex "#ffcb6b";
      blue = mkColorHex "#82aaff";
      magenta = mkColorHex "#c792ea";
      cyan = mkColorHex "#89ddff";
      white = mkColorHex "#ffffff";
    };

    cursor = {
      accent = bright.green;
      text = normal.black;
      cursor = normal.white;
    };

    primary = {
      background = normal.black;
      foreground = normal.white;
    };

    notification = {
      accent = bright.green;
      background = normal.black;
      foreground = normal.white;
    };

    utility = { };
  };
} 
