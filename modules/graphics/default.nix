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
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "575.64.05";
          sha256_64bit = "sha256-hfK1D5EiYcGRegss9+H5dDr/0Aj9wPIJ9NVWP3dNUC0=";
          sha256_aarch64 = "sha256-GRE9VEEosbY7TL4HPFoyo0Ac5jgBHsZg9sBKJ4BLhsA=";
          openSha256 = "sha256-mcbMVEyRxNyRrohgwWNylu45vIqF+flKHnmt47R//KU=";
          settingsSha256 = "sha256-o2zUnYFUQjHOcCrB0w/4L6xI1hVUXLAWgG2Y26BowBE=";
          persistencedSha256 = "sha256-2g5z7Pu8u2EiAh5givP5Q1Y4zk4Cbb06W37rf768NFU=";
        };
        modesetting.enable = true;
        dynamicBoost.enable = true;
        forceFullCompositionPipeline = true;
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
