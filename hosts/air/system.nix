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
      pkgs.anki-bin

      # multimedia
      pkgs.feh
      pkgs.syncplay
      pkgs.krita
      pkgs.audacity
      pkgs.ffmpeg
      pkgs.kdePackages.kdenlive
      pkgs.kdePackages.okular
      pkgs.picard
    ];
  };

  # general definitions
  system = {
    user.name = "barsoo";
    user.dirs = {
      torrents = config.system.user.utils.mkDir "/sdcard/torrents";
    };
    locale.locationName = "Bishkek";
  };

  # homebrew modules
  modules = {
    environment = {
      code.enable = true;
      cuda.enable = true;
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
      foot.enable = true;
      mpv.enable = true;
      bemenu.enable = true;
      obs.enable = true;
    };

    services = {
      dunst = {
        enable = true;
        notifySystemEvents = true;
      };
      jellyfin.enable = true;
      redshift.enable = true;
      bluetooth.enable = true;
      transmission.enable = true;
      sound.enable = true;
      gitlabRunner.enable = true;
      waybar.enable = true;
    };

    graphics = {
      enable = true;
      videoDrivers = "intel/nvidia";

      gtk.enable = true;
      niri.enable = true;

      monitor = {
        layout = [
          {
            identifier = "eDP-1";
            resolution = {
              width = 1920;
              height = 1200;
            };
            hz = 165;
          }
        ];
        dpi = 96;
      };
    };
  };

  # There is a bug when it resume from hybernation freezes
  systemd.services = builtins.listToAttrs (
    map
      (service: {
        name = service;
        value.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
      })
      [
        "systemd-suspend"
        "systemd-hibernate"
        "systemd-hybrid-sleep"
        "systemd-suspend-then-hibernate-sleep"
      ]
  );

  services.mullvad-vpn.enable = true;

  services.fstrim.enable = true;
  services.throttled = {
    enable = true;
  };
  services.thermald = {
    enable = true;
    ignoreCpuidCheck = true;
  };
  # services.thinkfan.enable = true;

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = config.system.user.name;
    dataDir = "${config.system.user.dirs.data.absolutePath}/syncthing";
    configDir = "${config.system.user.dirs.config.absolutePath}/syncthing";
    relay.enable = true;
    overrideFolders = false;
    overrideDevices = false;
  };
  services.anki-sync-server = {
    enable = true;
    openFirewall = true;
    address = "0.0.0.0";
    port = 27701;
    users = [
      {
        username = "default";
        password = "password";
      }
    ];
  };
}
