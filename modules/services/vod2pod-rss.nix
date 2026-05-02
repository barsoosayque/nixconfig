{
  pkgs,
  config,
  options,
  pkgsRepo,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption mkOption types;

  cfg = config.modules.services.vod2pod-rss;
in
{
  options.modules.services.vod2pod-rss = {
    enable = mkEnableOption "vod2pod-rss";

    credentialsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to file containing credentials as environment variables.
        Format: one KEY=value per line (like .env file).
        Supported variables: YT_API_KEY, TWITCH_SECRET, TWITCH_CLIENT_ID
        Example file content:
          YT_API_KEY=AIzaSy...
          TWITCH_SECRET=your-secret
          TWITCH_CLIENT_ID=your-client-id
      '';
      example = "/run/secrets/vod2pod-rss";
    };

    transcode = mkOption {
      type = types.bool;
      default = true;
      description = "Enable/disable transcoding (set false if only need feeds)";
    };

    port = mkOption {
      type = types.port;
      default = 8062;
      description = "Port to listen on (default: 8062)";
    };

    mp3Bitrate = mkOption {
      type = types.int;
      default = 192;
      description = "MP3 bitrate for transcoded stream";
    };

    subfolder = mkOption {
      type = types.str;
      default = "/";
      description = "Root path of the app, useful for reverse proxies";
    };

    validUrlDomains = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = "Comma-separated list of allowed URL domains (defaults to YouTube and Twitch)";
    };

    cacheTtl = mkOption {
      type = types.int;
      default = 600;
      description = "Cache TTL in seconds (default 600 = 10 minutes)";
    };

    youtubeYtDlpGetUrlExtraArgs = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = "Extra arguments to pass to yt-dlp for YouTube URLs (JSON array format)";
    };
  };

  config = mkIf cfg.enable {
    services.redis.servers.vod2pod-rss = {
      enable = true;
      port = 6379;
    };

    systemd.services.vod2pod-rss = {
      description = "Vod2Pod-RSS Service";
      after = [ "network.target" "redis-vod2pod-rss.service" ];
      wantedBy = [ "multi-user.target" ];
      requires = [ "redis-vod2pod-rss.service" ];

      serviceConfig = {
        ExecStart = pkgs.writeShellScript "vod2pod-rss-start" ''
          exec "${pkgsRepo.local.vod2pod-rss}/bin/app"
        '';
        Restart = "on-failure";
        RestartSec = "5s";
        DynamicUser = true;
        StateDirectory = "vod2pod-rss";
        EnvironmentFile = lib.optional (cfg.credentialsFile != null) cfg.credentialsFile;
      };

      environment = lib.filterAttrs (n: v: v != null) {
        VOD2POD_RSS_HOST = "0.0.0.0";
        VOD2POD_RSS_PORT = toString cfg.port;
        TRANSCODE = if cfg.transcode then "true" else "false";
        MP3_BITRATE = toString cfg.mp3Bitrate;
        SUBFOLDER = cfg.subfolder;
        CACHE_TTL = toString cfg.cacheTtl;
        VALID_URL_DOMAINS = if cfg.validUrlDomains != null then builtins.concatStringsSep "," cfg.validUrlDomains else null;
        YOUTUBE_YT_DLP_GET_URL_EXTRA_ARGS = if cfg.youtubeYtDlpGetUrlExtraArgs != null then builtins.toJSON cfg.youtubeYtDlpGetUrlExtraArgs else null;
        REDIS_URL = "redis://localhost:6379";
        TEMPLATES_DIR = "${pkgsRepo.local.vod2pod-rss}/share/vod2pod-rss/templates";
      };
    };
  };
}
