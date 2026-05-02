{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.programs.beets;
in
{
  options.modules.programs.beets = {
    enable = mkEnableOption "beets";
  };

  config = mkIf cfg.enable {
    system.user.hm.programs.beets = {
      enable = true;
      package = pkgs.beets;
      settings = rec {
        directory = config.system.user.dirs.music.absolutePath;
        library = "${config.system.user.dirs.music.absolutePath}/.library.db";
        import = {
          move = true;
          write = true;
        };
        paths = {
          default = "$albumartist/$albumtype/[$year] $album/$track. $title";
          singleton = "$artist/Unsorted/$title";
          "ostmedium::.+" = "OST/$album/$track. $title";
          # "mygenre::^$" = ".new/$albumartist/$album/$track. $title";
        };
        replace = {
          "[\\/]" = "∕";
          "[:]" = "꞉";
          "[*]" = "∗";
          "[?]" = "？";
          "[\"]" = "″";
          "[<]" = "‹";
          "[>]" = "›";
          "[|]" = "∣";
        };
        plugins = [
          "fromfilename"
          "musicbrainz"
          "embedart"
          "albumtypes"
          "fetchart"
          "lastgenre"
          "convert"
          "scrub"
          "advancedrewrite"
        ];
        include = [
          "rewrite.yaml"
        ];
        convert = {
          "auto" = false;
          "format" = "mp3";
          "bitrate" = 320;
          "dest" = "${directory}/.convert";
        };
        embedart = {
          auto = true;
          maxwidth = 1024;
          remove_art_file = true;
        };
      };
    };
  };
}
