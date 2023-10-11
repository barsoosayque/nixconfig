{ config, pkgs, pkgsRepo, ... }:

{
  imports = [ ];

  environment = {
    systemPackages = [
      # user
      pkgs.firefox
      pkgs.discord
      pkgs.tor-browser-bundle-bin
      pkgs.nicotine-plus
      pkgs.yt-dlp
      pkgs.blender
      pkgs.signal-desktop

      # multimedia
      pkgs.feh
      pkgs.syncplay
      pkgs.krita
      pkgs.tenacity
      pkgs.ffmpeg
      (pkgs.gifski.overrideAttrs(_: {
        buildFeatures = ["video"];
      }))
      pkgs.tagger
      # (pkgs.kdenlive.overrideAttrs (_: {
      #   buildInputs = [ pkgs.opencv ];
      # }))

      # libs
      pkgs.mono
      pkgs.libgdiplus
    ];
  };

  # TODO: droidcam module
  programs.droidcam.enable = true;

  fonts.packages = [
    pkgs.iosevka-bin
    pkgs.noto-fonts
    pkgs.noto-fonts-cjk
    pkgs.noto-fonts-emoji
  ];

  networking = {
    firewall.enable = false;
    interfaces.enp8s0.ipv4.addresses = [{
      address = "192.168.0.111";
      prefixLength = 24;
    }];
    defaultGateway = "192.168.0.1";
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
    useDHCP = false;
    # nameservers = [ "84.200.69.80" "84.200.70.40" ]; # https://dns.watch/
    # nameservers = [ "1.1.1.1" "1.0.0.1" ];
  };

  # general definitions
  system = {
    user.name = "barsoo";
    locale.locationName = "Abakan";

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
        };
        software = {
          steam = true;
          lutris = true;
          wine.enable = true;
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
      dmenu.enable = true;
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
      picom.enable = true;
      polybar.enable = true;
      grocy.enable = true;
    };

    x11 = {
      monitor.layout = [
        {
          identifier = "HDMI-0";
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
          "HDMI-0" = [ 1 2 3 4 5 6 7 8 ];
        };
      };
    };
  };

  # TODO: what is this
  programs.dconf.enable = true;
}

