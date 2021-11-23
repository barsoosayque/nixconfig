{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  inherit (pkgs) writeScript;

  cfg = config.modules.services.transmission;
  torrentDir = "${config.currentUser.dirs.download}/torrent";
in
{
  options.modules.services.transmission = {
    enable = mkEnableOption "transmission";
  };

  config = mkIf cfg.enable {
      currentUser.groups = [ "transmission" ];

      services.transmission = {
          enable = true;

          settings = {
            watch-dir-enabled = true;
            incomplete-dir-enabled = true;

            watch-dir = "${torrentDir}/torrents";
            incomplete-dir = "${torrentDir}/incomplete";
            download-dir = "${torrentDir}/complete";

            script-torrent-done-enabled = true;
            script-torrent-done-filename = config.system.events.onReloadScript;
          };
      };
  };
}
