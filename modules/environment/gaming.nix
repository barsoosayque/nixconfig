{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.environment.gaming;
in
{
  options.modules.environment.gaming = {
    enable = mkEnableOption "gaming environment";
  };

  config = mkIf cfg.enable {
    # xpadneo kernel module for xbox one controllers
    # https://github.com/atar-axis/xpadneo
    boot.extraModulePackages = with config.boot.kernelPackages; [
      xpadneo
    ];

    hardware.nvidia.package = config.boot.kernelPackages.nvidia_x11;

    nixpkgs.overlays = [
      (self: super: {
        # https://github.com/NixOS/nixpkgs/pull/126435
        steam = super.steam.override ({
          extraLibraries = pkgs: [ pkgs.pipewire ];
          extraProfile = ''
            unset VK_ICD_FILENAMES
            export VK_ICD_FILENAMES=${config.hardware.nvidia.package}/share/vulkan/icd.d/nvidia_icd.json:${config.hardware.nvidia.package.lib32}/share/vulkan/icd.d/nvidia_icd32.json'';
        });
      })
    ];

    environment.systemPackages = [
      pkgs.logmein-hamachi
      pkgs.lutris
      pkgs.steam
    ];

    hardware.opengl = {
      enable = true;
      driSupport32Bit = true;
      driSupport = true;
    };

    programs.steam.enable = true;
  };
}
