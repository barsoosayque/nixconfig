{ config, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption mkOption types;

  cfg = config.modules.services.mpd;

  settings = {
    dataDir = "${config.system.user.dirs.data.absolutePath}/mpd";
    port = 6602;
    address = "127.0.0.1";
    clientPort = 9092;
  };
in
{
  options.modules.services.mpd = {
    enable = mkEnableOption "mpd";
    enableWebClient = mkOption {
      type = with types; bool;
      default = true;
      description = "Enable mpd web client";
    };
    enableDiscordRPC = mkOption {
      type = with types; bool;
      default = false;
      description = "Enable mpd discord rpc";
    };
  };

  config = mkIf cfg.enable {
    services = {
      ympd = mkIf cfg.enableWebClient {
        enable = true;
        webPort = settings.clientPort;
        mpd = {
          port = settings.port;
          host = settings.address;
        };
      };

      mpd = {
        enable = true;

        user = config.system.user.name;
        musicDirectory = config.system.user.dirs.music.absolutePath;
        dataDir = settings.dataDir;

        network = {
          port = settings.port;
          listenAddress = settings.address;
        };

        startWhenNeeded = true;
        extraConfig = ''
          audio_output {
            type "pipewire"
            name "${config.system.user.name} MPD Pipewire output"
          }
        '';
      };
    };

    system.user.hm.services.mpd-discord-rpc = mkIf cfg.enableDiscordRPC {
      enable = true;
      settings = {
        hosts = ["${settings.address}:${toString settings.port}"];
      };
    };

    systemd.services.mpd.environment = {
      # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/609
      XDG_RUNTIME_DIR = "/run/user/${toString config.system.user.uid}"; # User-id 1000 must match above user. MPD will look inside this directory for the PipeWire socket.
    };
  };
}
