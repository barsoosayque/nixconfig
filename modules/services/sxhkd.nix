{
  config,
  options,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.services.sxhkd;
in
{
  options.modules.services.sxhkd = {
    enable = mkEnableOption "sxhkd";
  };

  config = mkIf cfg.enable {
    system.events.onReload = [ "pkill -USR1 -x sxhkd" ];

    system.keyboard.bindings = {
      "super + shift + r" = "${config.system.events.onReloadScript}";
    };

    system.user.hm.services.sxhkd = {
      enable = true;
      keybindings = config.system.keyboard.bindings;
    };
  };
}
