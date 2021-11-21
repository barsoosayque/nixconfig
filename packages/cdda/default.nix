{ pkgs, ... }:

with pkgs;
stdenv.mkDerivation rec {
  pname = "cataclysmdda";
  version = "2021-07-26-1520";

  buildInputs = [ SDL2 SDL2_image SDL2_mixer SDL2_ttf freetype ];
  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

  src = fetchurl {
    url = "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/cdda-experimental-${version}/cdda-linux-tiles-x64-${version}.tar.gz";
    sha256 = "1d779lyqi7i5i7q8195shkgmk9sdjmggn66k0n385rb0y1kxkqgz";
  };

  installPhase = ''
    install -m755 -D cataclysm-tiles $out/bin/cataclysm-tiles
    cp -r -t $out data gfx lang
    wrapProgram $out/bin/cataclysm-tiles --add-flags "--basepath $out --userdir ~/games/cataclysmdda/user"
  '';
}
