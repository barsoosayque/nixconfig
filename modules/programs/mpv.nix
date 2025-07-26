{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;

  cfg = config.modules.programs.mpv;
in
{
  options.modules.programs.mpv = {
    enable = mkEnableOption "mpv";

    screenshotsDir = mkOption {
      type = with types; str;
      default = "${config.system.user.dirs.pictures.absolutePath}/screenshots";
      description = "Where to put screenshots";
    };

    osdFont = {
      package = mkOption {
        type = with types; package;
        default = config.system.pretty.theme.fonts.primary.package;
        description = "OSD Font nix package";
      };

      name = mkOption {
        type = with types; str;
        default = config.system.pretty.theme.fonts.primary.name;
        description = "OSD Font name according to the package";
      };
    };

    subFont = {
      package = mkOption {
        type = with types; package;
        default = config.system.pretty.theme.fonts.secondary.package;
        description = "Subtitles font nix package";
      };

      name = mkOption {
        type = with types; str;
        default = config.system.pretty.theme.fonts.secondary.name;
        description = "Subtitles font name according to the package";
      };
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (self: super: {
        mpv = super.mpv.override {
          scripts = with pkgs.mpvScripts; [ simple-mpv-webui ];
        };
      })
    ];

    environment.systemPackages = [ pkgs.mpv ];
    fonts.packages = [ cfg.osdFont.package cfg.subFont.package ];

    system.user.hm.programs.mpv = {
      enable = true;
      config = {
        border = false;
        msg-module = true;
        msg-color = true;
        term-osd-bar = true;
        use-filedir-conf = true;
        keep-open = true;
        autofit-larger = "100%x95%";
        cursor-autohide-fs-only = true;
        input-media-keys = false;
        cursor-autohide = 1000;
        prefetch-playlist = true;
        force-seekable = true;

        screenshot-format = "png";
        screenshot-template = "${cfg.screenshotsDir}/%F (%P) %n";

        hls-bitrate = "max";

        cache = true;

        osd-level = 1;
        osd-duration = 2500;

        osd-font = cfg.osdFont.name;
        osd-font-size = 32;
        osd-color = "#CCFFFFFF";
        osd-border-color = "#DD322640";
        #osd-shadow-offset = 1;
        osd-bar-align-y = 0;
        osd-border-size = 2;
        osd-bar-h = 2;
        osd-bar-w = 60;

        sub-auto = "fuzzy";
        sub-file-paths-append = [ "ass" "srt" "sub" "subs" "subtitles" "RUS Subs" "SUB" ];
        embeddedfonts = false;
        sub-scale-with-window = true;
        sub-ass-override = "force";

        sub-font = cfg.subFont.name;
        sub-font-size = 40;
        sub-color = "#FFFFEE00";
        sub-border-color = "#FF000000";
        sub-border-size = 5;

        slang = [ "ru" "rus" "eng" "en" ];
        alang = [ "ja" "jp" "jpn" "en" "eng" "ru" ];

        audio-file-auto = "fuzzy";
        audio-pitch-correction = true;
        # pipewire audio device is crackling sometimes - very strange
        audio-device = "alsa";
        audio-samplerate = 44100;
        volume-max = 200;
        volume = 100;
        term-osd-bar-chars = [ "—●•" ];
      };
    };
  };
}
