{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types lists attrsets;
  
  cfg = config.modules.graphics;
in
{
  options.modules.graphics = {
    enable = mkEnableOption "graphics";

    videoDrivers = mkOption {
      type = with types; enum ["intel" "nvidia"];
      description = "Video drivers to use. See services.xserver.videoDrivers";
    };
  };

  config = mkIf cfg.enable {
    environment.sessionVariables = attrsets.optionalAttrs (cfg.videoDrivers == "nvidia") {
      VK_DRIVER_FILES = "${config.hardware.nvidia.package}/share/vulkan/icd.d/nvidia_icd.x86_64.json";
    };

    # Set drivers for both Wayland and X11
    services.xserver.videoDrivers = lists.optional (cfg.videoDrivers == "nvidia") "nvidia";

    hardware = {
      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        modesetting.enable = true;
        powerManagement.enable = true;
        powerManagement.finegrained = false;
        open = false;
      };
      graphics = {
        enable = true;
        extraPackages = with pkgs; lists.optionals (cfg.videoDrivers == "intel") [
          intel-media-driver
          vaapiIntel
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
    };

    nixpkgs.config.packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override {
        enableHybridCodec = cfg.videoDrivers == "intel";
      };
    };

    programs.dconf.enable = true;
  };
}
