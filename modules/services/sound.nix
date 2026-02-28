{
  config,
  options,
  pkgs,
  pkgsRepo,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.services.sound;
in
{
  options.modules.services.sound = {
    enable = mkEnableOption "sound";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.pavucontrol
      pkgs.easyeffects
    ];

    musnix = {
      enable = true;
      # broken ?
      # kernel.realtime = true;
    };

    programs.noisetorch.enable = true;
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
  };
}
