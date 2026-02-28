{
  pkgs,
  typeface ? [ ],
  map_typeface ? [ ],
  overmap_typeface ? [ ],
  config_dir ? null,
  ...
}:

with pkgs;
let
  inherit (lib.strings) concatLines splitString optionalString;
  inherit (lib.lists) last;
  inherit (builtins) toJSON map;

  mkFontdataPath = font: "${last (splitString "/" font)}";

  fontdata = {
    typeface = map mkFontdataPath typeface;
    map_typeface = map mkFontdataPath map_typeface;
    overmap_typeface = map mkFontdataPath overmap_typeface;
  };

  userdir = optionalString (!isNull config_dir) "--userdir ${config_dir}";
in
stdenv.mkDerivation rec {
  pname = "cataclysmdda";
  version = "2025-08-08-0308";

  buildInputs = [
    SDL2
    SDL2_image
    SDL2_mixer
    SDL2_ttf
    freetype
  ];
  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  src = fetchurl {
    url = "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/cdda-experimental-${version}/cdda-linux-with-graphics-and-sounds-x64-${version}.tar.gz";
    sha256 = "sha256-b2uTUjSagcNCB7RRPHu9/g2PmFkozWNxHixXKRUL/5w=";
  };

  installPhase = ''
    install -m755 -D cataclysm-tiles $out/bin/cataclysm-tiles
    cp -r -t $out data gfx lang
    ${concatLines (map (f: "ln -s -f ${f} $out/data/font/") typeface)}
    ${concatLines (map (f: "ln -s -f ${f} $out/data/font/") map_typeface)}
    ${concatLines (map (f: "ln -s -f ${f} $out/data/font/") overmap_typeface)}
    echo '${toJSON fontdata}' > $out/data/fontdata.json
    wrapProgram $out/bin/cataclysm-tiles --add-flags "--basepath $out ${userdir}"
  '';
}
