{ config, options, pkgs, lib, pkgsRepo, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  inherit (builtins) toJSON;

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
        # https://github.com/NixOS/nixpkgs/pull/157907
        steam = pkgsRepo.steam-fixes.steam;
        lutris = super.lutris.override ({
          extraPkgs = pkgs: [ pkgs.aria2 ];
        });
        tracker = super.tracker.overrideAttrs (_: {
          doCheck = false;
        });
      })
    ];

    # hardware.opengl.extraPackages = [
    #   (pkgs.runCommand "nvidia-icd" { } ''
    #     mkdir -p $out/share/vulkan/icd.d
    #     cp ${config.boot.kernelPackages.nvidia_x11}/share/vulkan/icd.d/nvidia_icd.x86_64.json $out/share/vulkan/icd.d/nvidia_icd.json
    #   '')
    # ];

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
