{ config, options, pkgs, pkgsLocal, lib, hostName, ... }:

with lib;
{
  options = {
    # Additional user configs to generate user-related stuff
    currentUser = {
      name = mkOption {
        type = types.str;
        default = "user";
        description = "User name to use throughout the system";
      };

      groups = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional user groups";
      };

      extraConfig = mkOption {
        type = types.attrs;
        default = {};
        description = "Additional config to pass to users.users.\${name}";
      };

      dirs = mkOption {
        type = types.attrs;
        description = "Set of XDG-like absoulte paths";
        readOnly = true;
      };
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

    # This is really annoying, sorry
    security.sudo.wheelNeedsPassword = false;

    fonts.fontconfig.enable = true;

    networking = {
      inherit hostName;
      useDHCP = false;
    };

    users = {
      mutableUsers = false;

      users."${username}" = rec {
        inherit home;
        description = "The one and only";
        extraGroups = [ "wheel" ] ++ config.currentUser.groups;
        isNormalUser = true;
        passwordFile = "${home}/.config/nixpass";
      } // config.currentUser.extraConfig;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users."${username}" = mkAliasDefinitions options.homeManager;
    };
    
    currentUser.dirs = {
      inherit home;

      desktop = "${home}/.local/desktop";
      publicShare = "${home}/.local/share";
      templates = "${home}/.local/templates";

      documents = "${home}/docs";
      download = "${home}/downloads";
      music = "${home}/music";
      pictures = "${home}/pictures";
      videos = "${home}/videos";
    };

    homeManager.xdg.userDirs = {
      inherit (currentUser.dirs) desktop publicShare templates documents download music pictures videos;

      enable = true;
      createDirectories = false;
    };
  };
}
