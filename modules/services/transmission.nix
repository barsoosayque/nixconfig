{ config, options, pkgs, lib, hmLib, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  inherit (builtins) toJSON;

  cfg = config.modules.services.transmission;
  torrentDir = config.system.user.dirs.torrents.absolutePath;

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
    rpc-authentication-required = false;

    umask = "000";
    peer-port-random-on-start = true;
  };
in
{
  options.modules.services.transmission = {
    enable = mkEnableOption "transmission";
  };

  config = mkIf cfg.enable {
    # system.user.hm = {
    #   home.activation.mkTorrentDirs = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
    #     install -d -o 'transmission' '${settings.download-dir}'
    #     install -d -o 'transmission' '${settings.watch-dir}'
    #     install -d -o 'transmission' '${settings.incomplete-dir}'
    #   '';
    # };

    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      openPeerPorts = true;
      settings = settings;
      downloadDirPermissions = "777";
      home = torrentDir;
    };
  };
}
