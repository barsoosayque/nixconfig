{ config, pkgs, pkgsLocal, ... }:

{
  imports = [];

  environment = {
    systemPackages = [
      # user
      pkgs.spotify
      pkgs.firefox
      pkgs.discord
      pkgs.blueberry

      # games
      pkgs.minecraft
      pkgsLocal.cdda

      # multimedia
      pkgs.feh
      pkgs.syncplay
      pkgs.krita

      # libs
      pkgs.mono
      pkgs.libgdiplus
    ];
  };

  fonts.fonts = [
    pkgs.iosevka-bin
    pkgs.noto-fonts
    pkgs.noto-fonts-cjk
    pkgs.noto-fonts-emoji
  ];

  networking = {
    firewall.enable = false;
    interfaces.enp8s0.useDHCP = true;
  };

  # user settings  
  currentUser = {
    name = "barsoo";
  };

  # general definitions
  system = {
    locale.locationName = "Abakan";

    pretty = {
      backgroundEnable = true;
    };
  };

  # homebrewk modules
  modules = {
    environment = {
      code.enable = true;
      gaming.enable = true;
      cli.enable = true;
    };

    programs = {
      alacritty.enable = true;
      mpv.enable = true;
      scissors.enable = true;
      dmenu.enable = true;
    };

    services = {
      dunst = {
        enable = true;
        notifySystemEvents = true;
      };
      redshift.enable = true;
      sxhkd.enable = true;
      bluetooth.enable = true;
      transmission.enable = true;
      sound.enable = true;
      #picom.enable = true;
    };

    x11 = {
      xsession = {
        videoDrivers = "nvidia";
        enable = true;
      };
      gtk.enable = true;
      bspwm = {
        enable = true;
        monitors = {
          "HDMI-0" = [ 1 2 3 4 ];
          "DP-5" = [ 5 6 7 8 ];
        };
      };
    };
  };

  # TODO: what is this
  programs.dconf.enable = true;
}

