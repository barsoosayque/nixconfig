{ config, pkgs, pkgsRepo, ... }:

{
  imports = [ ];

  environment = {
    systemPackages = [
      # user
      pkgs.spotify
      pkgs.firefox
      pkgs.discord
      pkgs.blueberry

      # games
      pkgs.minecraft
      pkgsRepo.local.cdda

      # multimedia
      pkgs.feh
      pkgs.syncplay
      pkgs.krita

      # libs
      pkgs.mono
      pkgs.libgdiplus
    ];
  };

  # TODO: droidcam module
  programs.droidcam.enable = true;

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

  # general definitions
  system = {
    user.name = "barsoo";
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
      android.enable = true;
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
      mpd.enable = true;
      #picom.enable = true;
    };

    x11 = {
      monitor.layout = [
        {
          identifier = "HDMI-0";
          resolution = { width = 1920; height = 1080; };
        }
        {
          identifier = "DP-5";
          resolution = { width = 1920; height = 1080; };
        }
      ];
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

