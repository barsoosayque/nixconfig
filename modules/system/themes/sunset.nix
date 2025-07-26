{ localLib, pkgs, ... }:

let
  inherit (localLib.colorUtils) mkColorHex;
in
{
  # Fonts
  fonts = rec {
    primary = {
      name = "Mononoki Nerd Font";
      package = pkgs.nerd-fonts.mononoki;
    };
    mono = {
      name = "Mononoki Nerd Font Mono";
      package = pkgs.nerd-fonts.mononoki;
    };
    secondary = {
      name = "Ubuntu Nerd Font Bold";
      package= pkgs.nerd-fonts.ubuntu;
    };
    bar = primary;
  };

  # General colorscheme: Melange
  colors = rec {
    normal = {
      black      = mkColorHex "#34302C";
      red        = mkColorHex "#BD8183";
      green      = mkColorHex "#78997A";
      yellow     = mkColorHex "#E49B5D";
      blue       = mkColorHex "#7F91B2";
      magenta    = mkColorHex "#B380B0";
      cyan       = mkColorHex "#7B9695";
      white      = mkColorHex "#C1A78E";
    };

    bright = {
      black      = mkColorHex "#867462";
      red        = mkColorHex "#D47766";
      green      = mkColorHex "#85B695";
      yellow     = mkColorHex "#EBC06D";
      blue       = mkColorHex "#A3A9CE";
      magenta    = mkColorHex "#CF9BC2";
      cyan       = mkColorHex "#89B3B6";
      white      = mkColorHex "#ECE1D7";
    };

    cursor = {
      accent = normal.yellow;
      text = normal.black;
      cursor = primary.foreground;
    };

    primary = {
      foreground = mkColorHex "#ECE1D7";
      background = mkColorHex "#292522";
    };

    notification = {
      accent = normal.green;
      background = primary.background.modify { a = 215; };
      foreground = primary.foreground;
    };

    bar = {
      background = primary.background.modify { a = 215; };
      foreground = primary.foreground;
      danger = normal.red;
      accent = normal.yellow;
      empty = normal.white;
    };

    window = {
      border = normal.black;
      active_border = bright.black;
      urgent_border = bright.yellow;
      shadow = primary.background.modify { a = 160; };
    };
  };
}
