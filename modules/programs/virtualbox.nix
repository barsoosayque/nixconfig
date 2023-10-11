{ config, pkgs, lib, ... }:

let
  inherit (lib) types mkIf mkOption mkEnableOption concatStringsSep;

  cfg = config.modules.programs.virtualbox;
in
{
  options.modules.programs.virtualbox = {
    enable = mkEnableOption "virtualbox";
  };

  config = mkIf cfg.enable {
    # environment.systemPackages = [ pkgs.virtualbox ];
    virtualisation.virtualbox = {
      host.enable = true;
    };
    users.extraGroups.vboxusers.members = [ config.system.user.name ];

    users.users."${config.system.user.name}".extraGroups = [ "libvirtd" ];

    environment.systemPackages = [ pkgs.virt-manager ];
    virtualisation.libvirtd = {
      enable = true;
    };

    system.user.hm.dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = ["qemu:///system"];
        uris = ["qemu:///system"];
      };
    };
  };
}
