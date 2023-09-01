{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.programs.obs;
in
{
  options.modules.programs.obs = {
    enable = mkEnableOption "obs";
  };

  config = mkIf cfg.enable {
    system.user.hm.programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
        obs-vkcapture
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
