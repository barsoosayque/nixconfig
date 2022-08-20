{ config, options, pkgs, lib, hostName, ... }:

{
  config = {
    system.stateVersion = "22.11";

    boot = {
      tmpOnTmpfs = false;
      cleanTmpDir = true;

      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };

    nix = {
      package = pkgs.nixUnstable;

      extraOptions = ''
        experimental-features = nix-command flakes
      '';

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
    };

    # Gamers.
    nixpkgs.config.allowUnfree = true;

    security.sudo ={
      enable = true;
      # This is really annoying, sorry
      wheelNeedsPassword = false;
    };

    fonts.fontconfig.enable = true;

    networking = {
      inherit hostName;
      useDHCP = false;
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
