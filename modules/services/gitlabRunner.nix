{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption concatStringsSep;

  cfg = config.modules.services.gitlabRunner;

  dockerHost = "127.0.0.1:2375";
in
{
  options.modules.services.gitlabRunner = {
    enable = mkEnableOption "Gitlab Runner";
  };

  config = mkIf cfg.enable {
    # enabling ip_forward on the host machine is important for the docker 
    # container to be able to perform networking tasks (such as cloning the gitlab repo)
    boot.kernel.sysctl."net.ipv4.ip_forward" = true;
    virtualisation.docker = {
      enable = true; 
    };

    services.gitlab-runner = {
      enable = true;
      services = {
        default = {
          # File should contain at least these two variables:
          # `CI_SERVER_URL`
          # `REGISTRATION_TOKEN`
          registrationConfigFile = "${config.system.user.dirs.config.absolutePath}/nixos/gitlab-runner";

          dockerImage = "alpine";
          dockerVolumes = [
            "/nix/store:/nix/store:ro"
            "/nix/var/nix/db:/nix/var/nix/db:ro"
            "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
          ];
          dockerDisableCache = true;
          runUntagged = true;
          preBuildScript = pkgs.writeScript "setup-container" ''
            mkdir -p -m 0755 /nix/var/log/nix/drvs
            mkdir -p -m 0755 /nix/var/nix/gcroots
            mkdir -p -m 0755 /nix/var/nix/profiles
            mkdir -p -m 0755 /nix/var/nix/temproots
            mkdir -p -m 0755 /nix/var/nix/userpool
            mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
            mkdir -p -m 1777 /nix/var/nix/profiles/per-user
            mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
            mkdir -p -m 0700 "$HOME/.nix-defexpr"

            . ${pkgs.nix}/etc/profile.d/nix.sh

            ${pkgs.nix}/bin/nix-env -i ${concatStringsSep " " (with pkgs; [ nix cacert git openssh curl ])}
            mkdir -p /root/.config/nix && echo "experimental-features = nix-command flakes ca-references" > /root/.config/nix/nix.conf

            ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixpkgs-unstable
            ${pkgs.nix}/bin/nix-channel --update nixpkgs
          '';

          environmentVariables = {
            ENV = "/etc/profile";
            USER = "root";
            NIX_REMOTE = "daemon";
            PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
            NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
          };

          tagList = [ "nix" ];
        };
      };
    };
  };
}
