{
  config,
  options,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.services.jellyfin;
in
{
  options.modules.services.jellyfin = {
    enable = mkEnableOption "jellyfin";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.jellyfin
      pkgs.jellyfin-web
      pkgs.jellyfin-ffmpeg
    ];

    services.jellyfin = {
      enable = true;
    };
  };
}
