{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types lists attrsets;
  
  cfg = config.modules.graphics;

  isNvidia = (cfg.videoDrivers == "nvidia" || cfg.videoDrivers == "intel/nvidia");
  isIntel = (cfg.videoDrivers == "intel" || cfg.videoDrivers == "intel/nvidia");
in
{
  options.modules.graphics = {
    enable = mkEnableOption "graphics";

    videoDrivers = mkOption {
      type = with types; enum ["intel" "nvidia" "intel/nvidia"];
      description = "Video drivers to use. See services.xserver.videoDrivers";
    };
  };

  config = mkIf cfg.enable {
    environment.sessionVariables = attrsets.optionalAttrs isNvidia {
      VK_DRIVER_FILES = "${config.hardware.nvidia.package}/share/vulkan/icd.d/nvidia_icd.x86_64.json";
    };

    # Set drivers for both Wayland and X11
    services.xserver.videoDrivers =
      (lists.optional isNvidia "nvidia");
      # ++ (lists.optional isIntel "modesetting");

    hardware = {
      nvidia = attrsets.optionalAttrs isNvidia {
        package = config.boot.kernelPackages.nvidiaPackages.beta;
        modesetting.enable = true;
        # dynamicBoost.enable = true;
        # forceFullCompositionPipeline = true;
        powerManagement.enable = true;
        powerManagement.finegrained = true;
        open = true;
      };
      graphics = {
        enable = true;
        extraPackages = with pkgs; lists.optionals isIntel [
          intel-media-driver
          intel-vaapi-driver
          intel-compute-runtime
          intel-ocl
          vpl-gpu-rt
        ];
      };
    };

    fonts.packages = [
      config.system.pretty.theme.fonts.primary.package
      config.system.pretty.theme.fonts.mono.package
      config.system.pretty.theme.fonts.secondary.package
      pkgs.twitter-color-emoji
      pkgs.nerd-fonts."m+"
      pkgs.noto-fonts
      # pkgs.noto-fonts-cjk-sans
    ];
  };
}
