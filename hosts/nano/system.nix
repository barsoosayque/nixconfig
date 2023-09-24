{ config, pkgs, pkgsRepo, ... }:

{
  imports = [ ];

  environment = {
    systemPackages = [
      # user
      pkgs.firefox
      pkgs.discord

      # multimedia
      pkgs.nsxiv
    ];
  };

  fonts.packages = [
    pkgs.iosevka-bin
    pkgs.noto-fonts
    pkgs.noto-fonts-cjk
    pkgs.noto-fonts-emoji
  ];

  # general definitions
  system = {
    user.name = "barsoo";
    locale.locationName = "Podgorica";

    pretty = {
      backgroundEnable = true;
    };
  };

  # homebrew modules
  modules = {
    environment = {
      code.enable = true;
      gaming = {
        enable = true;
        # gamepads = {
        #   xbox = true;
        # };
        # software = {
        #   steam = true;
        #   lutris = true;
        #   wine.enable = true;
        # };
        # games = {
        #   cdda = true;
        #   minecraft = true;
        # };
      };
      cli.enable = true;
      # android.enable = true;
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
      polybar.enable = true;
    };

    x11 = {
      monitor.layout = [
        {
          identifier = "HDMI-0";
          resolution = { width = 1366; height = 768; };
        }
      ];
      xsession = {
        videoDrivers = "intel";
        enable = true;
      };
      gtk.enable = true;
      bspwm = {
        enable = true;
        monitors = {
          "HDMI-0" = [ 1 2 3 4 5 6 7 8 ];
        };
      };
    };
  };

  # TODO: what is this
  programs.dconf.enable = true;
}

