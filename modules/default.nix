{
  config,
  options,
  pkgs,
  lib,
  hostName,
  ...
}:

{
  config = {
    system.stateVersion = "25.05";

    boot = {
      supportedFilesystems = [ "ntfs" ];
      tmp = {
        useTmpfs = true;
        cleanOnBoot = true;
      };

      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };

    nix = {
      # package = pkgs.nixVersions.git;

      extraOptions = ''
        experimental-features = nix-command flakes
      '';

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
        randomizedDelaySec = "10m";
      };
    };

    # Gamers.
    nixpkgs.config.allowUnfree = true;

    security.sudo = {
      enable = true;
      # This is really annoying, sorry
      wheelNeedsPassword = false;
    };

    fonts.fontconfig.enable = true;
    programs.nix-ld.enable = true;
    zramSwap.enable = true;

    networking = {
      inherit hostName;
      networkmanager = {
        enable = true;
        dns = "dnsmasq";
      };
      wireless.dbusControlled = true;
    };

    users = {
      mutableUsers = false;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}
