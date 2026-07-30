{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    types
    ;
  inherit (lib.strings) concatStringsSep optionalString;
  inherit (lib.attrsets) listToAttrs;
  inherit (lib.lists) concatMap;

  cfg = config.modules.services.transmission;
  torrentDir = config.system.user.dirs.torrents.absolutePath;
  rpcPort = 9091;
  remote = "${pkgs.transmission_4}/bin/transmission-remote 127.0.0.1:${toString rpcPort}";

  notifyTorrentDone = config.modules.services.dunst.notify {
    title = "Transmission";
    msg = "$TR_TORRENT_NAME";
    icon = "folder-download-line";
  };

  # Looks up the finished torrent's label and, if it matches a known category,
  # moves its data into complete/<category> before notifying as usual.
  torrentDoneScript = pkgs.writeScript "transmission-torrent-done" ''
    #!${pkgs.dash}/bin/dash

    LABEL=$(${remote} -j -t "$TR_TORRENT_ID" -i | ${pkgs.jq}/bin/jq -r '.result.torrents[0].labels[0] // empty')

    ${optionalString (cfg.categories != [ ]) ''
      case "$LABEL" in
        ${concatStringsSep "|" cfg.categories})
          ${remote} -t "$TR_TORRENT_ID" --move "${torrentDir}/complete/$LABEL"
          ;;
      esac
    ''}

    ${notifyTorrentDone}
  '';

  # Watches torrents/<category> for dropped .torrent files and adds them with
  # that category as their label (Transmission's native watch-dir is flat and
  # can't do this itself).
  categoryWatcherScript =
    category:
    pkgs.writeShellScript "transmission-watch-${category}" ''
      DIR="${torrentDir}/torrents/${category}"

      ${pkgs.inotify-tools}/bin/inotifywait -m -e close_write -e moved_to --format '%f' "$DIR" |
      while IFS= read -r name; do
        case "$name" in
          *.torrent)
            ${remote} --add "$DIR/$name" --labels "${category}" && rm -f "$DIR/$name"
            ;;
        esac
      done
    '';

  categoryWatcherServices = listToAttrs (
    map (category: {
      name = "transmission-watch-${category}";
      value = {
        description = "Watch and auto-tag torrents dropped into the ${category} watch folder";
        after = [ "transmission.service" ];
        partOf = [ "transmission.service" ];
        wantedBy = [ "transmission.service" ];

        serviceConfig = {
          Type = "simple";
          User = "transmission";
          Group = "transmission";
          Restart = "always";
          ExecStart = categoryWatcherScript category;
        };
      };
    }) cfg.categories
  );

  categoryTmpfilesRules = concatMap (category: [
    "d ${torrentDir}/torrents/${category} 0777 transmission transmission -"
    "d ${torrentDir}/complete/${category} 0777 transmission transmission -"
  ]) cfg.categories;

  settings = {
    watch-dir-enabled = true;
    incomplete-dir-enabled = true;

    watch-dir = "${torrentDir}/torrents";
    incomplete-dir = "${torrentDir}/incomplete";
    download-dir = "${torrentDir}/complete";

    script-torrent-done-enabled = true;
    script-torrent-done-filename = torrentDoneScript;

    rpc-enabled = true;
    rpc-bind-address = "127.0.0.1";
    rpc-port = rpcPort;
    rpc-whitelist-enabled = false;
    rpc-host-whitelist-enabled = false;
    rpc-authentication-required = false;
    bind-address-ipv4 = "0.0.0.0";
    bind-address-ipv6 = "::";

    umask = "000";
    peer-port = 51413;
    pex-enabled = true;
    dht-enabled = true;
    lpd-enabled = true;
  };
in
{
  options.modules.services.transmission = {
    enable = mkEnableOption "transmission";

    categories = mkOption {
      type = with types; listOf str;
      default = [
        "anime"
        "books"
        "manga"
        "games"
        "shows"
      ];
      description = ''
        Category names. For each, a watch subfolder (torrents/<category>) is monitored
        for dropped .torrent files, which get auto-labeled <category> and added; completed
        downloads with that label get moved to complete/<category>.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      openPeerPorts = true;
      settings = settings;
      downloadDirPermissions = "777";
      home = torrentDir;
    };

    systemd.tmpfiles.rules = categoryTmpfilesRules;
    systemd.services = categoryWatcherServices;
  };
}
