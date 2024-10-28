{ pkgs, ... }:

with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "mcman";
  version = "0.4.5";

  src = fetchFromGitHub {
    owner = "ParadigmMC";
    repo = pname;
    rev = version;
    sha256 = "sha256-/WIm2MFj2++QVCATDkYz2h4Jm+0RzxzVFIYrZubEgIQ=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    allowBuiltinFetchGit = true;
    # outputHashes = {
    #   "data-url-0.1.0" = "sha256-rESQz5jjNpVfIuTaRCAV2TLeUs09lOaLZVACsb/3Adg=";
    #   "web_app_manifest-0.0.0" = "sha256-CpND9SxPwFmXe6fINrvd/7+HHzESh/O4GMJzaKQIjc8=";
    #   "mime-0.4.0-a.0" = "sha256-LjM7LH6rL3moCKxVsA+RUL9lfnvY31IrqHa9pDIAZNE=";
    # };
  };

  meta = with stdenv.lib; {
    description = "Powerful Minecraft Server Manager CLI. Easily install jars (server, plugins & mods) and write config files.";
    homepage = "https://github.com/${owner}/${repo}";
  };
}
