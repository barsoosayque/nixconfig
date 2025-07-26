{ localLib, pkgs, ... }:

let
  inherit (localLib.colorUtils) mkColorHex;
in
{
  # Fonts
  fonts = rec {
    primary = {
      name = "Iosevka Nerd Font";
      package = pkgs.nerd-fonts.iosevka;
    };
    mono = {
      name = "Iosevka Nerd Font Mono";
      package = pkgs.nerd-fonts.iosevka;
    };
    secondary = {
      name = "Ubuntu Bold";
      package= pkgs.ubuntu_font_family;
    };
    bar = primary;
  };

  # General colorscheme: Base16 Atelier heath dark
  colors = rec {
    normal = {
      black = mkColorHex "#1b181b";
      red = mkColorHex "#ca402b";
      green = mkColorHex "#379a37";
      yellow = mkColorHex "#bb8a35";
      blue = mkColorHex "#516aec";
      magenta = mkColorHex "#7b59c0";
      cyan = mkColorHex "#159393";
      white = mkColorHex "#ab9bab";
    };

    bright = {
      black = mkColorHex "#776977";
      red = mkColorHex "#ca402b";
      green = mkColorHex "#379a37";
      yellow = mkColorHex "#bb8a35";
      blue = mkColorHex "#516aec";
      magenta = mkColorHex "#7b59c0";
      cyan = mkColorHex "#159393";
      white = mkColorHex "#f7f3f7";
    };

    cursor = {
      accent = normal.green;
      text = normal.black;
      cursor = bright.white;
    };

    primary = {
      background = normal.black;
      foreground = bright.white;
    };

    notification = {
      accent = normal.green;
      background = primary.background.modify { a = 180; };
      foreground = primary.foreground;
    };

    bar = {
      background = primary.background.modify { a = 180; };
      foreground = primary.foreground;
      danger = normal.red;
      accent = normal.green;
      empty = normal.white;
    };

    window = {
      border = normal.black;
      active_border = normal.green;
    };
  };
}
