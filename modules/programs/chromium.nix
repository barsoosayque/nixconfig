{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption mkOption types;

  cfg = config.modules.programs.chromium;

  # Chromium can't present WebGPU on Wayland with the NVIDIA dGPU, so this launcher
  # runs it on Xwayland with PRIME offload and the Vulkan/ANGLE backend forced on.
  # The separate --user-data-dir keeps those flags out of the normal Chromium profile.
  chromium-webgpu = pkgs.writeShellApplication {
    name = "chromium-webgpu";
    text = ''
      export DISPLAY="''${DISPLAY:-:0}"
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __GLX_VENDOR_LIBRARY_NAME=nvidia

      exec ${lib.getExe cfg.package} \
        --user-data-dir=${cfg.webgpuUserDataDir} \
        --password-store=basic \
        --ozone-platform=x11 \
        --enable-unsafe-webgpu \
        --enable-features=Vulkan,VulkanFromANGLE,DefaultANGLEVulkan \
        --ignore-gpu-blocklist \
        --new-window "$@"
    '';
  };
in
{
  options.modules.programs.chromium = {
    enable = mkEnableOption "chromium";

    package = mkOption {
      type = types.package;
      default = pkgs.ungoogled-chromium;
      description = "Chromium package to install and use for chromium-webgpu.";
    };

    webgpu = mkOption {
      type = types.bool;
      default = true;
      description = "Install the chromium-webgpu launcher (Xwayland + NVIDIA PRIME offload + Vulkan/ANGLE).";
    };

    webgpuUserDataDir = mkOption {
      type = types.str;
      default = "/tmp/chromium-webgpu";
      description = "Profile directory chromium-webgpu uses, kept apart from the normal Chromium profile.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ] ++ lib.optional cfg.webgpu chromium-webgpu;
  };
}
