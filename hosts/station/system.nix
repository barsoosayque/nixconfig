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

  # TODO: good xserver config
  services.xserver.screenSection = ''
    DefaultDepth    24
    Option         "Stereo" "0"
    Option         "nvidiaXineramaInfoOrder" "DFP-4"
    Option         "metamodes" "HDMI-0: 1920x1080 +0+0, DP-5: 1920x1080 +1920+0"
    Option         "SLI" "Off"
    Option         "MultiGPU" "Off"
    Option         "BaseMosaic" "off"
    SubSection     "Display"
        Depth       24
    EndSubSection
  '';

  # TODO: what is this
  programs.dconf.enable = true;
}

