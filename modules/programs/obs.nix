{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.programs.obs;

  phoneCamDevice = 10;

  # Streams the camera of a phone connected via USB into the loopback device.
  # Extra args are passed to scrcpy, e.g. `phone-cam --camera-facing=front`.
  phoneCam = pkgs.writeShellScriptBin "phone-cam" ''
    exec ${pkgs.scrcpy}/bin/scrcpy \
      --video-source=camera \
      --camera-facing=back \
      --camera-size=1920x1080 \
      --camera-fps=30 \
      --v4l2-sink=/dev/video${toString phoneCamDevice} \
      --no-video-playback \
      --no-audio \
      "$@"
  '';
in
{
  options.modules.programs.obs = {
    enable = mkEnableOption "obs";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.scrcpy
      phoneCam
    ];

    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];
    boot.extraModprobeConfig = ''
      options v4l2loopback video_nr=${toString phoneCamDevice} card_label="Phone Camera" exclusive_caps=1
    '';

    system.user.hm.programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
        obs-vkcapture
        obs-tuna
        obs-text-pthread
        input-overlay
        # TODO: upload this plugin to nixpkgs
        # (pkgs.libsForQt5.callPackage
        #   ({ stdenv
        #    , cmake
        #    , pkg-config
        #    , ninja
        #    , obs-studio
        #    , ffmpeg
        #    , curl
        #    , qtbase
        #    , libX11
        #    , fetchFromGitHub
        #    }:

        #     stdenv.mkDerivation rec {
        #       pname = "StreamFX";
        #       version = "0.12.0a151";

        #       src = fetchFromGitHub {
        #         owner = "Xaymar";
        #         repo = "obs-StreamFX";
        #         rev = version;
        #         sha256 = "sha256-OcHH726CJBnDBzIFKtJZHuleCT9KINn9MV5IEIq4VWY=";
        #         fetchSubmodules = true;
        #       };

        #       dontWrapQtApps = true;
        #       cmakeFlags = [
        #         "-DSTANDALONE=YES"
        #         "-Dlibobs_DIR=${obs-studio}"
        #         "-DQt5_DIR=${qtbase}"
        #         "-DFFmpeg_DIR=${ffmpeg}"
        #         # "-DVERSION=${version}"
        #         "-DSTRUCTURE_PACKAGEMANAGER=ON"
        #       ];

        #       nativeBuildInputs = [ cmake ninja ];
        #       buildInputs = [ libX11 ];
        #     })
        #   { })
      ];
    };
  };
}
