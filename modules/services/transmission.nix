{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  inherit (builtins) toJSON;

  cfg = config.modules.services.transmission;
  torrentDir = "${config.userDirs.download}/torrent";

  settings = {
    watch-dir-enabled = true;
    incomplete-dir-enabled = true;

    watch-dir = "${torrentDir}/torrents";
    incomplete-dir = "${torrentDir}/incomplete";
    download-dir = "${torrentDir}/complete";

    script-torrent-done-enabled = true;
    script-torrent-done-filename = config.system.events.onTorrentDoneScript;
  };
in
{
  options.modules.services.transmission = {
    enable = mkEnableOption "transmission";
  };

  config = mkIf cfg.enable {
    system.activationScripts.transmission-daemon = ''
      install -d -o '${config.currentUser.name}' '${settings.download-dir}'
      install -d -o '${config.currentUser.name}' '${settings.watch-dir}'
      install -d -o '${config.currentUser.name}' '${settings.incomplete-dir}'
      '';

    homeManager.xdg.configFile."transmission-daemon/settings.json".text = toJSON settings;

    environment.systemPackages = [ pkgs.transmission ];

    systemd.services.transmission = {
      description = "Transmission BitTorrent Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart="${pkgs.transmission}/bin/transmission-daemon -f -g '${config.userDirs.config}/transmission-daemon'";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        User="${config.currentUser.name}";
      };
    };
  };
}
