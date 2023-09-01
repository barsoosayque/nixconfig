{ config, options, pkgs, lib, pkgsRepo, ... }:

let
  inherit (lib) types mkIf mkEnableOption mkOption lists attrsets;
  inherit (builtins) toJSON fetchurl;

  cfg = config.modules.environment.gaming;
  
  cdda = (pkgsRepo.local.cdda.override rec {
    typeface = [ "${pkgs.iosevka-comfy.comfy}/share/fonts/truetype/iosevka-comfy-bold.ttf" ];
    map_typeface = [ "${pkgs.ocr-a}/share/fonts/truetype/OCRA.ttf" ];
    overmap_typeface = map_typeface;

    config_dir = "${config.system.user.dirs.games.relativePath}/cataclysmdda/";
  });
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
        package = mkOption {
          type = with types; package;
          default = pkgs.wine64;
          description = "Wine package";
        };
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
      (attrsets.optionalAttrs cfg.software.steam {
        # https://github.com/NixOS/nixpkgs/pull/157907
        steam = (pkgsRepo.steamFixes.steam.override {
          extraProfile = ''
            export VK_ICD_FILENAMES=${config.hardware.nvidia.package}/share/vulkan/icd.d/nvidia_icd.json:${config.hardware.nvidia.package.lib32}/share/vulkan/icd.d/nvidia_icd32.json:$VK_ICD_FILENAMES
          '';
        });
      }) // (attrsets.optionalAttrs cfg.software.lutris {
        lutris = (super.lutris.override (
          let
            mb_glew = pkgs.glew.overrideAttrs (_: {
              postInstall = ''ln -s $out/lib/libGLEW.so $out/lib/libGLEW.so.2.1'';
            });
            mb_fmod = pkgs.fmodex.overrideAttrs (prev: {
              installPhase = prev.installPhase + ''ls $out/lib; ln -s $out/lib/libfmodex.so $out/lib/libfmodex64.so; ls $out/lib'';
            });
          in
          {
            extraPkgs = pkgs: [ pkgs.aria2 pkgs.vulkan-tools ];
            extraLibraries = pkgs: [ mb_glew mb_fmod pkgs.curlWithGnuTls pkgs.gnome.zenity pkgs.libnice ];
          }
        ));
      })
    )];

    environment.systemPackages = [
      pkgs.logmein-hamachi
      pkgs.vulkan-tools
    ] ++ (lists.optionals cfg.software.wine.enable [
      cfg.software.wine.package
      pkgs.winetricks
    ]) ++ (lists.optional cfg.software.retroarch 
      (pkgs.retroarch.override {
        cores = with pkgs.libretro; [
          # Playstation
          swanstation # PS1 emulator  
          ppsspp # PSP emulator

          # Nintendo
          mesen # NES emulator
          parallel-n64 # Nintendo 64 emulator  
          desmume # Nintendo DS emulator 
          snes9x # SNES emulator 
          vba-next # Gameboy advaтсe emulator
        ];
      })
    ) ++ (lists.optional cfg.software.steam pkgs.steam)
      ++ (lists.optional cfg.software.lutris pkgs.lutris)
      ++ (lists.optional cfg.games.veloren pkgs.airshipper)
      ++ (lists.optional cfg.games.minecraft pkgs.prismlauncher)
      ++ (lists.optional cfg.games.cdda cdda)
    ;

    hardware = {
      nvidia.package = config.boot.kernelPackages.nvidia_x11;
      opengl = {
        enable = true;
        driSupport32Bit = true;
        driSupport = true;
      };
    };
    boot.extraModulePackages = lists.optional cfg.gamepads.xbox config.boot.kernelPackages.xpadneo;

    services.joycond.enable = cfg.gamepads.nintendo;
    programs.steam.enable = cfg.software.steam;

    system.user.hm.home.file = attrsets.optionalAttrs cfg.games.cdda {
      "${config.system.user.dirs.games.relativePath}/cataclysmdda/game".source = "${cdda}";
      "${config.system.user.dirs.games.relativePath}/cataclysmdda/config/fonts.json".source = "${cdda}/data/fontdata.json";
    };
  };
}
