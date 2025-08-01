{ config, pkgs, pkgsRepo, ... }:

{
  imports = [ ];

  environment = {
    systemPackages = [
      # user
      pkgs.firefox
      pkgs.discord
      pkgs.nicotine-plus
      # pkgs.yt-dlp
      pkgs.blender
      pkgs.obsidian

      # multimedia
      pkgs.feh
      pkgs.syncplay
      pkgs.krita
      pkgs.audacity
      pkgs.ffmpeg
      pkgs.kdenlive
      pkgs.scrcpy
      pkgs.kdePackages.okular

      # libs
      pkgs.mono
      pkgs.libgdiplus
    ];
  };

  networking = {
    firewall.enable = false;
    useDHCP = false;
  };

  # general definitions
  system = {
    user.name = "barsoo";
    locale.locationName = "Bangkok";

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
        gamepads = {
          xbox = true;
          nintendo = false;
        };
        software = {
          steam = true;
          lutris = true;
          wine.enable = true;
          retroarch = true;
        };
        games = {
          cdda = true;
          minecraft = true;
        };
      };
      cli.enable = true;
      android.enable = true;
    };

    programs = {
      alacritty.enable = true;
      mpv.enable = true;
      scissors.enable = true;
      bemenu.enable = true;
      obs.enable = true;
      beets.enable = true;
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
      gitlabRunner.enable = true;
      # picom.enable = false;
      polybar.enable = true;
      # grocy.enable = false;
      # miracast.enable = true;
    };

    x11 = {
      monitor.layout = [
        # {
        #   identifier = "HDMI-0";
        #   resolution = { width = 1920; height = 1080; };
        # }
        {
          identifier = "DP-0";
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
          # "HDMI-0" = [ 1 2 3 4 ];
          # "DP-0" = [ 5 6 7 8 ];
          "DP-0" = [ 1 2 3 4 5 6 7 8 ];
        };
      };
    };
  };


  # services.samba = {
  #   enable = true;
  #   securityType = "user";
  #   openFirewall = true;
  #   extraConfig = ''
  #     security = user 
  #     hosts allow = 192.168.1. 192.168.0. 127.0.0.1 localhost
  #     hosts deny = 0.0.0.0/0
  #     guest account = nobody
  #     map to guest = bad user
  #   '';
  #   shares = {
  #     lutris = {
  #       path = "/home/barsoo/.cache/lutris";
  #       browseable = "yes";
  #       "read only" = "yes";
  #       "guest ok" = "yes";
  #       "public" = "yes";
  #       "force user" = "barsoo";
  #     };
  #   };
  # };
}

