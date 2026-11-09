{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.services.wpaperd;
in
{
  options.modules.services.wpaperd = {
    enable = mkEnableOption "wpaperd wallpaper daemon";
  };

  config = mkIf cfg.enable {
    # A user service rather than an onWMLoaded spawn: wpaperd segfaults in
    # mesa when an output goes away (e.g. unplugging or Mod+Shift+C → off),
    # and this brings the wallpaper back on its own.
    system.user.hm.systemd.user.services.wpaperd = {
      Unit = {
        Description = "wpaperd wallpaper daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        ExecStart = "${pkgs.wpaperd}/bin/wpaperd";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

    system.user.hm.xdg.configFile."wpaperd/config.toml".text = ''
      [default]
      path = "${config.system.user.dirs.config.absolutePath}/wpaperd/rotation"
      duration = "10m"
      sorting = "random"
    '';
  };
}
