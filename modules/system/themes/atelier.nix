{ localLib, ... }:

let
  inherit (localLib.colorUtils) mkColorHex;
in
{
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
      accent = bright.green;
      text = normal.black;
      cursor = normal.white;
    };

    primary = {
      background = normal.black;
      foreground = normal.white;
    };

    notification = {
      accent = normal.green;
      background = normal.black.modify { a = 150; };
      foreground = normal.white;
    };

    window = {
      border = normal.black;
      active_border = normal.green;
    };
  };
}
