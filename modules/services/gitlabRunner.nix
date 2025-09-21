{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption concatStringsSep;
  inherit (lib.strings) makeBinPath;

  cfg = config.modules.services.gitlabRunner;

  env = pkgs.buildEnv {
    name = "gitlab-docker-env";
    paths = with pkgs; [
      bash
      toybox
      gnugrep
      nixVersions.latest
      git
      curlFull
      openssh
      openssl
    ];
    pathsToLink = [ "/bin" "/etc" ];
  };
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
          description = "nixos-runner";
          # File should contain at least these two variables:
          # CI_SERVER_URL=<CI server URL>
          # CI_SERVER_TOKEN=<runner authentication token secret>
          authenticationTokenConfigFile = "${config.system.user.dirs.config.absolutePath}/nixos/gitlab-runner";

          executor = "docker";
          dockerImage = "alpine:latest";
          dockerVolumes = [
            "/nix/store:/nix/store:ro"
            "/nix/var/nix/db:/nix/var/nix/db:ro"
            "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
          ];
          dockerDisableCache = true;
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

            . ${pkgs.nix}/etc/profile.d/nix-daemon.sh

            mkdir -p /etc/ssl/certs
            cp -a "${pkgs.cacert}/etc/ssl/certs" /etc/ssl/certs 

            mkdir -p /root/.config/nix && echo "experimental-features = nix-command flakes" > /root/.config/nix/nix.conf
          '';
          environmentVariables = {
            ENV = "/etc/profile";
            USER = "root";
            NIX_REMOTE = "daemon";
            PATH = "${env}/bin:/sbin:/usr/bin:/usr/sbin";
          };
        };
      };
    };
  };
}
