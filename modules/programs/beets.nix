{ config, pkgs, lib, ... }:

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
      # mpdIntegration = {
      #   enableStats = true;
      #   enableUpdate = true;
      # };
      settings = {
        directory = config.system.user.dirs.music.absolutePath;
        library = "${config.system.user.dirs.music.absolutePath}/.library.db";
        import = {
          move = true;
          write = true;
        };
        paths = {
          default = "$mygenre/$albumartist/$albumtype/[$year] $album/$track. $title";
          singleton = "$mygenre/$artist/Unsorted/$title";
          "ostmedium::.+" = "OST/$ostmedium/$ostwhat/$album/$track. $title";
          "mygenre::^$" = ".new/$albumartist/$album/$track. $title";
        };
        replace = {
          "[\\/]" = "_";
        };
        plugins = [
          "fromfilename"
          "musicbrainz"
          "embedart"
          "albumtypes"
          "fetchart"  
          "lastgenre"
        ];
        embedart = {
          auto = true;
          maxwidth = 1024;
          remove_art_file = true;
        };
      };
    };
  };
}
