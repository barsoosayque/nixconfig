{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;

  cfg = config.modules.programs.alacritty;
  pkg = pkgs.alacritty;

  iosevkaCustom = pkgs.nerdfonts.override {
    fonts = [ "Iosevka" ];
  };
in
{
  options.modules.programs.alacritty = {
    enable = mkEnableOption "alacritty";

    font = {
      package = mkOption {
        type = with types; package;
        default = iosevkaCustom;
        description = "Font nix package";
      };

      name = mkOption {
        type = with types; str;
        default = "Iosevka";
        description = "Font name according to the package";
      };
    };
  };

  config = mkIf cfg.enable {
    system.keyboard.bindings = {
      "super + Return" = "${pkg}/bin/alacritty";
    };

    fonts.fonts = [ cfg.font.package ];
    environment.systemPackages = [ pkg ];

    system.user.hm = {
      programs.alacritty = {
        enable = true;

        settings = {
          # General settings
          env = {
            TERM = "xterm-256color";
          };
          mouse = {
            hide_when_typing = true;
          };
          bell = {
            animation = "Linear";
            duration = 0;
          };

          # Geometry
          window = {
            dimensions = {
              columns = 0;
              lines = 0;
            };
            padding = {
              x = 10;
              y = 10;
            };
            dynamic_padding = true;
            dynamic_title = true;
            decorations = "full";
            opacity = 0.9;
          };

          # Text
          font = {
            normal = {
              family = "${cfg.font.name}";
              style = "Medium";
            };
            bold = {
              family = "${cfg.font.name}";
              style = "Heavy";
            };
            size = 12.0;
            glyph_offset = {
              x = 0;
              y = 0;
            };
          };
          draw_bold_text_with_bright_colors = true;

          colors = config.system.pretty.theme.colors;
        };
      };
    };

  };
}
