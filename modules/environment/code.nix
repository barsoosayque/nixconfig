{ config, options, pkgs, lib, pkgsRepo, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;
  inherit (lib.lists) optionals;
  inherit (pkgs.vscode-utils) extensionsFromVscodeMarketplace;
  inherit (builtins) readFile;

  cfg = config.modules.environment.code;
in
{
  options.modules.environment.code = {
    enable = mkEnableOption "code environment";

    enableRust = mkOption {
      type = with types; bool;
      default = true;
      description = "Enable Rust environment";
    };
  };

  config = mkIf cfg.enable {
    fonts.packages = [ pkgs.fira-code ];

    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';

    environment.systemPackages = [
      pkgs.direnv
      pkgs.cloc

      pkgs.cmake
      pkgs.gnumake
      pkgs.clang
      pkgs.clang-tools
      pkgs.git
      pkgs.delta
      pkgs.gitu

      # https://github.com/helix-editor/helix/issues/9866
      # pkgsRepo.helix.default
      pkgs.helix
    ] ++ optionals cfg.enableRust [ pkgs.rust-analyzer pkgs.rustfmt ];

    system.user.hm = {
      xdg.configFile."helix/themes/nixos-generated.toml".text = ''
        inherits = "base16_transparent"
        "ui.background" = {}
      '';

      xdg.configFile."helix/config.toml".text = ''
          theme = "nixos-generated"

          [editor]
          line-number = "relative"
          bufferline = "always"
          color-modes = true
          
          [editor.statusline]
          left = ["mode", "spacer", "spinner", "spacer", "version-control", "spacer", "workspace-diagnostics"]
          center = ["file-modification-indicator", "file-name", "position" ]
          right = ["file-encoding", "file-type", "total-line-numbers"]
          mode.normal = "󰇀"
          mode.insert = "󰆈"
          mode.select = "󰒉"
          
          [editor.lsp]
          enable = true
          display-inlay-hints = true
      '';

      xdg.configFile."zellij/config.kdl".text = ''
        themes {
          default {
            fg "${config.system.pretty.theme.colors.primary.foreground.hexRGB}"
            bg "${config.system.pretty.theme.colors.primary.background.hexRGB}"
            black "${config.system.pretty.theme.colors.normal.black.hexRGB}"
            red "${config.system.pretty.theme.colors.normal.red.hexRGB}"
            green "${config.system.pretty.theme.colors.normal.green.hexRGB}"
            yellow "${config.system.pretty.theme.colors.normal.yellow.hexRGB}"
            blue "${config.system.pretty.theme.colors.normal.blue.hexRGB}"
            magenta "${config.system.pretty.theme.colors.normal.magenta.hexRGB}"
            cyan "${config.system.pretty.theme.colors.normal.cyan.hexRGB}"
            white "${config.system.pretty.theme.colors.normal.white.hexRGB}"
            orange "${config.system.pretty.theme.colors.bright.yellow.hexRGB}"
          }
        }
        pane_frames false 
        default_layout "compact"
        simplified_ui true
        ui {
            pane_frames {
                rounded_corners true
            }
        }

        disable_session_metadata true
        session_serialization false
        show_startup_tips false
        show_release_notes false
        on_force_close "quit"
      '' + readFile ./zellij-config.kdl;

      services.ssh-agent.enable = true;

      programs = {
        zellij = {
          enable = true;
          enableZshIntegration = true;
          enableBashIntegration = false;
          enableFishIntegration = false;
        };

        direnv = {
          enable = true;
          enableBashIntegration = false;
          enableFishIntegration = false;
          nix-direnv.enable = true;
        };

        ssh = {
          enable = true;
          addKeysToAgent = "yes";
        };

        git = {
          enable = true;
          lfs.enable = true;

          userName = "barsoosayque";
          userEmail = "shtoshich@gmail.com";

          ignores = [
            ".local"
          ];

          difftastic = {
            enable = true;
            background = "dark";
            display = "inline";
          };

          extraConfig = {
            pull.rebase = true;
            rebase.autostash = true;
            branch.autosetuprebase = "always";
            push.autoSetupRemote = true;

            url = {
              "https://github.com/" = {
                insteadOf = [
                  "gh:"
                  "github:"
                ];
              };
            };
          };
        };
      };
    };
  };
}
