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
  inherit (builtins) toJSON;

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
  version = "2026-07-18-0036";

  buildInputs = [
    sdl3
    sdl3-image
    sdl3-mixer
    sdl3-ttf
    freetype
  ];
  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  src = fetchurl {
    url = "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/cdda-experimental-${version}/cdda-linux-with-graphics-and-sounds-x64-${version}.tar.gz";
    # url = "https://github.com/CleverRaven/Cataclysm-DDA/releases/download/0.I/cdda-linux-with-graphics-and-sounds-x64-${version}.tar.gz";
    sha256 = "sha256-RA5+w2LBl+QqRTt6xEmcaGx91LR82WbZUUqCu3r9QgQ=";
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
