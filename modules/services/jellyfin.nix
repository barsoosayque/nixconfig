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
      pkgs.jellyfin-ffmpeg
    ];

    services.jellyfin = {
      enable = true;
    };

    # nixpkgs' jellyfin wrapper hardcodes `--webdir=<bundled jellyfin-web>`
    # ahead of any args we pass, and Jellyfin's own CLI parser refuses to start
    # if `--webdir` appears twice ("Option 'w, webdir' is defined multiple
    # times") - so it can't be overridden without rebuilding jellyfin from
    # source. Serve Feishin's web build as its own site instead, using a plain
    # static file server rather than pulling in all of nginx for one SPA.
    systemd.services.feishin-web = {
      description = "Serve Feishin's web build (in place of jellyfin-web)";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.miniserve} --index index.html --spa -p 8097 -i 0.0.0.0 ${pkgs.feishin-web}";
        DynamicUser = true;
        Restart = "on-failure";
      };
    };
  };
}
