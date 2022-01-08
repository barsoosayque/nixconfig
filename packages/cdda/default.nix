{ pkgs, ... }:

with pkgs;
stdenv.mkDerivation rec {
  pname = "cataclysmdda";
  version = "2021-12-16-0958";

  buildInputs = [ SDL2 SDL2_image SDL2_mixer SDL2_ttf freetype ];
  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

  src = fetchurl {
    url = "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/cdda-experimental-${version}/cdda-linux-tiles-x64-${version}.tar.gz";
    sha256 = "dbe803786e553c80d434da3759a4825ba7c9858d17acd8216bb9004afa069777";
  };

  installPhase = ''
    install -m755 -D cataclysm-tiles $out/bin/cataclysm-tiles
    cp -r -t $out data gfx lang
    wrapProgram $out/bin/cataclysm-tiles --add-flags "--basepath $out --userdir ~/games/cataclysmdda/user"
  '';
}
