{ config, options, pkgs, lib, hmLib, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  inherit (builtins) toJSON;

  cfg = config.modules.services.transmission;
  torrentDir = "${config.system.user.dirs.download.absolutePath}/torrent";

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
    system.user.hm = {
      home.activation.mkTorrentDirs = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
        install -d -o '${config.system.user.name}' '${settings.download-dir}'
        install -d -o '${config.system.user.name}' '${settings.watch-dir}'
        install -d -o '${config.system.user.name}' '${settings.incomplete-dir}'
      '';

      xdg.configFile."transmission-daemon/settings.json".text = toJSON settings;
    };

    # environment.systemPackages = [ pkgs.transmission_4 ];

    systemd.services.transmission = {
      description = "Transmission BitTorrent Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = config.system.user.name;
        ExecStart = "${pkgs.transmission_4}/bin/transmission-daemon -f -g '${config.system.user.dirs.config.absolutePath}/transmission-daemon'";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      };
    };
    
    # systemd.services.autoMoveTorrents = {
    #   description = "Move *.torrent files from downloads to transmission";

    #   serviceConfig = {
    #     User = config.system.user.name;
    #     ExecStart = "${pkgs.transmission}/bin/transmission-daemon -f -g '${config.system.user.dirs.config.absolutePath}/transmission-daemon'";
    #     ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
    #   };
    # }
  };
}
