{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption lists;

  cfg = config.modules.environment.cli;
in
{
  options.modules.environment.cli = {
    enable = mkEnableOption "cli environment";

    enableFlexing = mkEnableOption "cli tools to make pretty screenshots";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = [
        # System
        pkgs.htop
        pkgs.bottom
        pkgs.openssl
        pkgs.file
        pkgs.unzip
        pkgs.unrar
        pkgs.curl
        pkgs.xclip
        pkgs.sad
        pkgs.fzf

        # Utility
        pkgs.nnn
        pkgs.imagemagick 

        # Text
        pkgs.neovim
      ] ++ lists.optionals cfg.enableFlexing [
        pkgs.neofetch
        pkgs.pipes
        pkgs.terminal-parrot
        pkgs.cbonsai
      ];

      variables = {
        EDITOR = "hx";
        VISUAL = "hx";
      };

      # https://nix-community.github.io/home-manager/options.html#opt-programs.zsh.enableCompletion
      pathsToLink = [ "/share/zsh" ];
    };

    users.defaultUserShell = pkgs.zsh;

    programs.zsh.enable = true;

    system.user.hm = {
      programs = {
        zsh = {
          enable = true;
          enableCompletion = true;
          syntaxHighlighting.enable = true;
          enableAutosuggestions = true;
          dotDir = "${config.system.user.dirs.data.relativePath}/zsh";

          history = {
            ignoreDups = true;
            path = "${config.system.user.dirs.data.relativePath}/zsh/history";
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
