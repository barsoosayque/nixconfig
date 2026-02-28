{
  config,
  options,
  pkgs,
  pkgsRepo,
  lib,
  hmLib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  inherit (pkgs) writeText fetchFromGitHub;

  cfg = config.modules.services.miracast;
in
{
  options.modules.services.miracast = {
    enable = mkEnableOption "miracast";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # miraclecast
      gnome-network-displays
      # dnsmasq
    ];

    nixpkgs.overlays = [
      (self: super: {
        wpa_supplicant = super.wpa_supplicant.overrideAttrs (old: {
          extraConfig = old.extraConfig + ''
            CONFIG_WIFI_DISPLAY=y
            CONFIG_WFD=y
            CONFIG_CTRL_IFACE=y
            CONFIG_P2P=y
            CONFIG_AP=y
            CONFIG_WPS=y
            CONFIG_WPS2=y
          '';
        });
      })
    ];

    # xdg.portal.enable = true;

    # xdg.portal.xdgOpenUsePortal = true;
    # xdg.portal.extraPortals = [
    #   #pkgs.xdg-desktop-portal-gtk
    #   pkgs.xdg-desktop-portal-gnome
    #   pkgs.xdg-desktop-portal-wlr
    # ];

    # networking.firewall.trustedInterfaces = [ "p2p-wl+" ];

    # networking.firewall.allowedTCPPorts = [ 7236 7250 ];
    # networking.firewall.allowedUDPPorts = [ 7236 5353 ];
  };
}
