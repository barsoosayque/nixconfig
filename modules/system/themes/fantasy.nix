{
  # General colorscheme: Base16 Material Palenight 256
  colors = rec {
    normal = {
      black = "#292d3e";
      red = "#f07178";
      green = "#c3e88d";
      yellow = "#ffcb6b";
      blue = "#82aaff";
      magenta = "#c792ea";
      cyan = "#89ddff";
      white = "#959dcb";
    };
    
    bright = {
      black = "#676e95";
      red = "#f07178";
      green = "#c3e88d";
      yellow = "#ffcb6b";
      blue = "#82aaff";
      magenta = "#c792ea";
      cyan = "#89ddff";
      white = "#ffffff";
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

    utility = {

    };
  };
}