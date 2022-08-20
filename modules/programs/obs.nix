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
        (pkgs.libsForQt5.callPackage
          ({ stdenv
           , cmake
           , pkg-config
           , ninja
           , obs-studio
           , ffmpeg
           , curl
           , qtbase
           , libX11
           , fetchFromGitHub
           }:

            stdenv.mkDerivation rec {
              pname = "StreamFX";
              version = "0.12.0a45";

              src = fetchFromGitHub {
                owner = "Xaymar";
                repo = "obs-StreamFX";
                rev = version;
                sha256 = "sha256-EkfSBTYLq73TOEhX6MGmN1yAd3prJ/2ij6LM24l2xIU=";
                fetchSubmodules = true;
              };

              dontWrapQtApps = true;
              cmakeFlags = [
                "-DOBS_DOWNLOAD=OFF"
                "-DOBS_PATH=${obs-studio}/lib"
                "-DVERSION=${version}"
                "-DSTRUCTURE_PACKAGEMANAGER=ON"
              ];

              nativeBuildInputs = [ cmake ninja ];
              buildInputs = [ obs-studio qtbase libX11 curl ffmpeg ];
            })
          { })
      ];
    };
  };
}
