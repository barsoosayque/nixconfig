{ config, pkgs, pkgsRepo, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;

  cfg = config.modules.programs.beets;
in
{
  options.modules.programs.beets = {
    enable = mkEnableOption "beets";
  };

  config = mkIf cfg.enable {
    system.user.hm.programs.beets = {
      enable = true;
      package = pkgs.beets-unstable;
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
          comp = "Compilation/[$year] $album/$track. $title";
          "albumtype:soundtrack" = "OST/$album/$track. $title";
        };
        plugins = [
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
