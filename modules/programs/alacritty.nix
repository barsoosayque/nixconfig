{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;
  inherit (builtins) mapAttrs;

  cfg = config.modules.programs.alacritty;
  pkg = pkgs.alacritty;

  mapColors = colors:
    mapAttrs (n: v: v.hexRGB) colors;
in
{
  options.modules.programs.alacritty = {
    enable = mkEnableOption "alacritty";
  };

  config = mkIf cfg.enable {
    system.keyboard.bindings = {
      "super + Return" = "${pkg}/bin/alacritty";
    };

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
              x = 40;
              y = 30;
            };
            dynamic_padding = true;
            dynamic_title = true;
            decorations = "full";
            opacity = 0.85;
          };

          # Text
          font = {
            normal = {
              family = config.system.pretty.theme.fonts.primary.name;
              style = "Bold";
            };
            bold = {
              family = config.system.pretty.theme.fonts.primary.name;
              style = "Bold";
            };
            size = 12.0;
            glyph_offset = {
              x = 0;
              y = 0;
            };
          };

          colors = {
            normal = mapColors config.system.pretty.theme.colors.normal;
            bright = mapColors config.system.pretty.theme.colors.bright;
            draw_bold_text_with_bright_colors = true;
          };
        };
      };
    };

  };
}
