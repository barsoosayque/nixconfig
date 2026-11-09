{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.services.tandoor;

  # Local-only instance: strip Django's password-strength validators (rejects
  # "too common" passwords etc). There's no env toggle for these — they're
  # hardcoded in settings.py — so drop them by appending an override at EOF,
  # where the last module-level assignment wins regardless of upstream layout.
  package = pkgs.tandoor-recipes.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      echo "AUTH_PASSWORD_VALIDATORS = []" >> recipes/settings.py
    '';
  });
in
{
  options.modules.services.tandoor = {
    enable = mkEnableOption "tandoor recipes";
  };

  config = mkIf cfg.enable {
    services.tandoor-recipes = {
      enable = true;
      package = package;
      address = "0.0.0.0";
      port = 9099;
      # Django rejects requests whose Host header isn't in ALLOWED_HOSTS (the
      # module defaults this to `address`, so 127.0.0.1 / the LAN IP 400s).
      extraConfig.ALLOWED_HOSTS = "*";
      # Keep media out of the state dir, next to db.sqlite3 (GHSA-g8w3-p77x-mmxh).
      # Default from stateVersion 26.05 on; set explicitly since we are on 25.05.
      extraConfig.MEDIA_ROOT = "/var/lib/tandoor-recipes/media";
    };
  };
}
