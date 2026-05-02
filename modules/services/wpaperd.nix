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
    system.events.onWMLoaded = [ "${pkgs.wpaperd}/bin/wpaperd -d" ];

    system.user.hm.xdg.configFile."wpaperd/config.toml".text = ''
      [default]
      path = "${config.system.user.dirs.config.absolutePath}/wpaperd/rotation"
      duration = "10m"
      sorting = "random"
    '';
  };
}
