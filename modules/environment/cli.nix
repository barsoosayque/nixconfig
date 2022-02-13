{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  cfg = config.modules.environment.cli;
in
{
  options.modules.environment.cli = {
    enable = mkEnableOption "cli environment";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = [
        # System
        pkgs.htop
        pkgs.openssl
        pkgs.file
        pkgs.unzip
        pkgs.unrar
        pkgs.curl

        # Text
        pkgs.kakoune
        pkgs.neovim
      ];

      variables = {
        EDITOR = "kak";
        VISUAL = "kak";
      };

      # https://nix-community.github.io/home-manager/options.html#opt-programs.zsh.enableCompletion
      pathsToLink = [ "/share/zsh" ];
    };

    users.defaultUserShell = pkgs.zsh;

    system.user.hm = {
      programs = {
        zsh = {
          enable = true;
          enableCompletion = true;
          enableSyntaxHighlighting = true;
          enableAutosuggestions = true;
          dotDir = "${config.system.user.dirs.data.relativePath}/zsh";

          history = {
            ignoreDups = true;
            path = "${config.system.user.dirs.data.absolutePath}/zsh/history";
          };

          localVariables = {
            ENABLE_CORRECTION = true;
            PROMPT = "%# [%B%F{yellow}%n%f@%F{blue}%m%f%b] %F{green}%~%f: ";
          };

          shellAliases = {
            vim = "nvim";
            vi = "nvim";
            mv = "mv -v";
            cp = "cp -v";
            ls = "${pkgs.exa}/bin/exa --icons --group-directories-first --classify ";
          };
        };

        exa = {
          enable = true;
        };
        bat = {
          enable = true;
        };
      };
    };
  };
}
