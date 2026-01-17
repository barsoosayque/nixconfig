{ config, pkgs, lib, pkgsRepo, ... }:

let
  inherit (lib) mkIf mkEnableOption lists attrsets;

  cfg = config.modules.environment.gaming;
  
  cdda = (pkgsRepo.local.cdda.override rec {
    typeface = [ "${pkgs.iosevka-comfy.comfy}/share/fonts/truetype/iosevka-comfy-normalboldupright.ttf" ];
    map_typeface = [ "${pkgs.ocr-a}/share/fonts/truetype/OCRA.ttf" ];
    overmap_typeface = map_typeface;

    config_dir = "${config.system.user.dirs.games.relativePath}/cataclysmdda/";
  });
  jdk = pkgs.openjdk17.override {
    # enableJavaFX = true;
  };
  jdk8 = pkgs.jdk8;
in
{
  options.modules.environment.gaming = {
    enable = mkEnableOption "gaming environment";

    gamepads = {
      xbox = mkEnableOption "xbox controller";
      nintendo = mkEnableOption "nintendo controller";
    };

    software = {
      steam = mkEnableOption "steam";
      lutris = mkEnableOption "lutris";
      retroarch = mkEnableOption "retroarch";
      wine = {
        enable = mkEnableOption "wine";
      };
    };

    games = {
      cdda = mkEnableOption "cataclysm: dark days ahead";
      veloren = mkEnableOption "veloren";
      minecraft = mkEnableOption "minecraft";
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [(self: super: 
      {
      } // (attrsets.optionalAttrs cfg.software.steam {
        # # https://github.com/NixOS/nixpkgs/pull/157907
        # steam = (pkgsRepo.steamFixes.steam.override {
        #   extraProfile = ''
        #     export VK_ICD_FILENAMES=${config.hardware.nvidia.package}/share/vulkan/icd.d/nvidia_icd.json:${config.hardware.nvidia.package.lib32}/share/vulkan/icd.d/nvidia_icd32.json:$VK_ICD_FILENAMES
        #   '';
        # });
      }) // (attrsets.optionalAttrs cfg.software.lutris {
        lutris = (super.lutris.override (
          let
            mb_glew = super.glew.overrideAttrs (_: {
              postInstall = ''ln -s $out/lib/libGLEW.so $out/lib/libGLEW.so.2.1'';
            });
            mb_fmod = super.fmodex.overrideAttrs (prev: {
              installPhase = prev.installPhase + ''ls $out/lib; ln -s $out/lib/libfmodex.so $out/lib/libfmodex64.so; ls $out/lib'';
            });
          in
          {
            extraPkgs = pkgs: [ 
              pkgs.jdk 
              pkgs.aria2 
              pkgs.vulkan-tools
            ];
            extraLibraries = pkgs: [ 
              mb_glew 
              mb_fmod 
              pkgs.curlWithGnuTls
              # pkgs.zenity 
              pkgs.libnice 
            ];
          }
        ));
      })
    )];

    environment.systemPackages = [
      pkgs.vulkan-tools
      pkgs.protonup-ng
    ] ++ (lists.optionals cfg.software.wine.enable [
      pkgs.wine
      pkgs.wine64
      pkgs.winetricks
    ]) ++ (lists.optional cfg.software.retroarch 
      (pkgs.retroarch.withCores(cores: with cores; [
          # Playstation
          swanstation # PS1 emulator  
          ppsspp # PSP emulator

          # Nintendo
          mesen # NES emulator
          parallel-n64 # Nintendo 64 emulator  
          desmume # Nintendo DS emulator 
          snes9x # SNES emulator 
          vba-next # Gameboy advaтсe emulator
        ]
      ))
    ) ++ (lists.optional cfg.software.steam pkgs.steam)
      ++ (lists.optional cfg.software.lutris pkgs.lutris)
      ++ (lists.optional cfg.games.veloren pkgs.airshipper)
      ++ (lists.optional cfg.games.minecraft pkgs.prismlauncher)
      ++ (lists.optional cfg.games.minecraft pkgsRepo.local.mcman)
      ++ (lists.optional cfg.games.cdda cdda)
    ;
    environment.sessionVariables = rec {
      JAVA_HOME = "${jdk}/lib/openjdk";
      JAVA_BIN = "${JAVA_HOME}/bin/java";
      JAVA_8_HOME = "${jdk8}/lib/openjdk";
      JAVA_8_BIN = "${JAVA_8_HOME}/bin/java";
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "~/.steam/root/compatibilitytools.d";
    };

    boot.extraModulePackages = lists.optional cfg.gamepads.xbox config.boot.kernelPackages.xpadneo;

    services.joycond.enable = cfg.gamepads.nintendo;
    services.zerotierone = {
      enable = true;
    };
    programs.steam = {
      enable = cfg.software.steam;
    };
    programs.java = {
      enable = true;
      package = jdk;
    };
    programs.gamemode.enable = true;
    programs.gamescope = {
      enable = true;
      capSysNice = true;
      env = {
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };
    };

    system.user.hm.home.file = attrsets.optionalAttrs cfg.games.cdda {
      "${config.system.user.dirs.games.relativePath}/cataclysmdda/game".source = "${cdda}";
      "${config.system.user.dirs.games.relativePath}/cataclysmdda/config/fonts.json".source = "${cdda}/data/fontdata.json";
    };
  };
}
