{ config, options, pkgs, pkgsLocal, lib, hmLib, ... }:

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

    rpc-enabled = true;
    rpc-bind-address = "127.0.0.1";
    rpc-port = 9091;
    rpc-whitelist-enabled = false;
    rpc-host-whitelist-enabled = false;
  };
in
{
  options.modules.services.transmission = {
    enable = mkEnableOption "transmission";
  };

  config = mkIf cfg.enable {
    homeManager ={
      home.activation.mkTorrentDirs = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
        install -d -o '${config.currentUser.name}' '${settings.download-dir}'
        install -d -o '${config.currentUser.name}' '${settings.watch-dir}'
        install -d -o '${config.currentUser.name}' '${settings.incomplete-dir}'
      '';

      xdg.configFile."transmission-daemon/settings.json".text = toJSON settings;
    };

    environment.systemPackages = [ pkgs.transmission ];

    systemd.services.transmission = {
      description = "Transmission BitTorrent Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = config.currentUser.name;
        ExecStart="${pkgs.transmission}/bin/transmission-daemon -f -g '${config.userDirs.config}/transmission-daemon'";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      };
    };
  };
}
