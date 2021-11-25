{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  inherit (pkgs) writeScript;

  cfg = config.modules.services.transmission;
  torrentDir = "${config.userDirs.download}/torrent";
in
{
  options.modules.services.transmission = {
    enable = mkEnableOption "transmission";
  };

  config = mkIf cfg.enable {
    # security.sudo.extraRules = [
    #   { 
    #     users = [ config.currentUser.name ]; 
    #     runAs = "transmission"; 
    #     commands = [ { command = "ALL"; options = [ "NOPASSWD" "SETENV" ]; } ];
    #   }
    # ];

    currentUser.extraGroups = [ "transmission" ];

    services.transmission = {
      enable = true;
      
      # This is wrong, but I couldn't figure out how to send notifications
      # from "transmission" user to current user, because sudo -u USER
      # doesn't work from transmission service for some reason
      # user = config.currentUser.name;

      settings = {
        extraFlags = [ "--log-debug" "--logfile /var/lib/transmission/log" ];

        watch-dir-enabled = true;
        incomplete-dir-enabled = true;

        watch-dir = "${torrentDir}/torrents";
        incomplete-dir = "${torrentDir}/incomplete";
        download-dir = "${torrentDir}/complete";

        script-torrent-done-enabled = true;
        script-torrent-done-filename = config.system.events.onTorrentDoneScript;
      };
    };
  };
}
