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

      # system
      pkgs.htop
      pkgs.openssl
      pkgs.file
      pkgs.unzip
      pkgs.unrar
      pkgs.curl
      pkgs.git

      # libs
      pkgs.mono
      pkgs.libgdiplus

      # Text
      pkgs.kakoune
      pkgs.neovim
    ];

    variables = {
      EDITOR = "kak";
      VISUAL = "kak";
    };

    shellAliases = {
      vim = "nvim";
      vi = "nvim";
    };

    shells = [ pkgs.zsh ];
  };
  
  # TODO: merge with redshift
  time.timeZone = "Asia/Krasnoyarsk";

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

  currentUser = {
    name = "barsoo";
  };

  events.onTest = [ "sleep 1s"];

  # homebrewk modules
  modules = {
    # TODO: alacritty + dmenu own modules
    keyboard.bindings = {
      "super + Return" = "${pkgs.alacritty}/bin/alacritty";
      "super + d" = "${pkgs.dmenu}/bin/dmenu_run";
      "super + T" = "${config.events.onTestCmd}";
    };

    environment = {
      code.enable = true;
      gaming.enable = true;
    };

    programs = {
      mpv.enable = true;
      scissors.enable = true;
    };

    services = {
      redshift = {
        enable = true;
        location = "Abakan";
      };
      sxhkd.enable = true;
      bluetooth.enable = true;
      transmission.enable = true;
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

  programs.dconf.enable = true;
}

