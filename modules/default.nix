{ config, options, pkgs, pkgsLocal, lib, hostName, ... }:

with lib;
{
  options = {
    # Additional user configs to generate user-related stuff
    currentUser = mkOption {
      type = types.attrs;
      default = {};
      description = "Configs for current user (nixos)";
    };

    userDirs = mkOption {
      type = types.attrs;
      description = "Set of XDG-like absoulte paths";
      readOnly = true;
    };

    homeManager = mkOption {
      type = types.attrs;
      default = {};
      description = "Home-manager configs for current user";
    };
  };

  config = let
    username = config.currentUser.name;
    home = "/home/${username}";
  in rec {
    # systemd-boot EFI boot loader by default
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
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
      users."${username}" = mkAliasDefinitions options.currentUser;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users."${username}" = mkAliasDefinitions options.homeManager;
    };
    
    currentUser = {
      inherit home;
      uid = 1000;
      description = "The one and only";
      extraGroups = [ "wheel" ];
      isNormalUser = true;
      passwordFile = "${home}/.config/nixpass";
    };

    userDirs = {
      inherit home;

      data = "${home}/.local/share";
      desktop = "${home}/.local/desktop";
      publicShare = "${home}/.local/public";
      templates = "${home}/.local/templates";

      documents = "${home}/docs";
      download = "${home}/downloads";
      music = "${home}/music";
      pictures = "${home}/pictures";
      videos = "${home}/videos";
    };

    homeManager.xdg = {
      enable = true;

      userDirs = {
        inherit (userDirs) desktop publicShare templates documents download music pictures videos;

        enable = true;
        createDirectories = false;
      };
    };
  };
}
