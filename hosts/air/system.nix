{ config, pkgs, ... }:

{
  imports = [ ];

  environment = {
    systemPackages = [
      # user
      pkgs.librewolf
      pkgs.discord
      pkgs.telegram-desktop
      pkgs.nicotine-plus
      pkgs.blender
      pkgs.obsidian

      # multimedia
      pkgs.feh
      pkgs.syncplay
      pkgs.krita
      pkgs.audacity
      pkgs.ffmpeg
      pkgs.kdePackages.kdenlive
      pkgs.kdePackages.okular
    ];
  };

  networking.firewall = {
    enable = false;
  };

  # general definitions
  system = {
    user.name = "barsoo";
    user.dirs = {
      torrents = config.system.user.utils.mkDir "/sdcard/torrents";
    };
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
      picom.enable = true;
      polybar.enable = true;
    };

    graphics = {
      enable = true;
      videoDrivers = "intel/nvidia";

      gtk.enable = true;
      monitor = {
        layout = [
          {
            identifier = "eDP-1";
            resolution = { width = 1920; height = 1200; };
            hz = 165;
          }
        ];
        dpi = 96;
      };
      bspwm = {
        enable = true;
        monitors = {
          "eDP-1" = [ 1 2 3 4 5 6 7 8 ];
        };
      };
      x11.enable = true;
    };
  };

  services.mullvad-vpn.enable = true;
  # required for wireguard mullvad tunnels
  # see: https://discourse.nixos.org/t/connected-to-mullvadvpn-but-no-internet-connection/35803/10
  networking.resolvconf.enable = false;

  services.fstrim.enable = true;
  services.throttled = {
    enable = true;
  };
  services.thermald = {
    enable = true;
    ignoreCpuidCheck = true;
  };

  # move zcfan to its own module
  # environment.etc = {
  #   "zcfan.conf".text = ''
  #     max_temp 85
  #     med_temp 65
  #     low_temp 50
  #     temp_hysteresis 10

  #     max_level full-speed
  #     med_level 4
  #     low_level 1
  #   '';
  # };
  # systemd.services.zcfan = {
  #   description = "zcfan: A zero-configuration fan daemon for ThinkPads. ";
  #   wantedBy = [ "default.target" ];
  #   serviceConfig = {
  #     ExecStart = "${pkgs.zcfan}/bin/zcfan";
  #     Type = "simple";
  #   };
  # };
}

