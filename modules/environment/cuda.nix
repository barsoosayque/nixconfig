{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.environment.cli;
in
{
  options.modules.environment.cuda = {
    enable = mkEnableOption "cuda environment";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = 
    let
      cudaEnv = pkgs.buildFHSEnv {
        name = "cuda-env";
        targetPkgs = pkgs: with pkgs; [ 
          git
          gitRepo
          gnupg
          autoconf
          curl
          procps
          gnumake
          util-linux
          m4
          gperf
          unzip
          cudatoolkit
          libGLU libGL
          xorg.libXi xorg.libXmu freeglut
          xorg.libXext xorg.libX11 xorg.libXv xorg.libXrandr zlib 
          ncurses5
          stdenv.cc
          binutils
          glibc
          cacert
        ];
        multiPkgs = pkgs: with pkgs; [ zlib ];
        runScript = "bash";
        profile = ''
          export CUDA_PATH=${pkgs.cudatoolkit}
          export EXTRA_LDFLAGS="-L/lib -L${options.hardware.nvidia.package}/lib"
          export EXTRA_CCFLAGS="-I/usr/include"
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        '';
      };
    cudaRun = 
      pkgs.writeShellScriptBin "cuda-run" ''
        exec ${cudaEnv}/bin/cuda-env -c "$@"
      '';
    in [ cudaRun ];
  };
}
