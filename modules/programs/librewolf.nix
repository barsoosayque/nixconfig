{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption mkOption types;

  cfg = config.modules.programs.librewolf;

  webgpuPrefs = ''
    defaultPref("dom.webgpu.enabled", true);
    defaultPref("dom.webgpu.allow-present-without-readback", false);
  '';

  pkg = pkgs.librewolf.override {
    extraPrefs = lib.optionalString cfg.webgpu webgpuPrefs;
  };
in
{
  options.modules.programs.librewolf = {
    enable = mkEnableOption "librewolf";

    webgpu = mkOption {
      type = types.bool;
      default = true;
      description = "Enable hardware WebGPU (works around the Wayland DMABUF black-canvas bug via the readback present path).";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkg ];
  };
}
