{ pkgs, ... }:

let
  inherit (builtins) concatStringsSep;

  colorToPrecent = colors:
    concatStringsSep "," (map (v: toString (v / 255.0 * 100.0)) colors);

  mkIconDerivation = input@{ id, color ? [ 255 255 255 ] }: pkgs.stdenv.mkDerivation rec {
    pname = "remixicon-icon-${id}";
    version = "2.5.0";

    buildInputs = [ pkgs.findutils pkgs.resvg pkgs.imagemagick ];

    src = fetchGit {
      url = "https://github.com/Remix-Design/RemixIcon.git";
      ref = "refs/tags/v${version}";
      rev = "755818100db4687fd907ecaef9f57cc9ea77d0d8";
    };

    buildPhase = ''
      ICON=$(find icons -name "${id}.svg" | head -n 1)

      if [ -z "$ICON" ]; then
        echo "NO ICON FOUND ${id}: $ICON"
        exit 1
      fi

      resvg -w 200 -h 200 $ICON icon-black.png
      convert icon-black.png -colorize "${colorToPrecent color}" icon.png
    '';

    installPhase = ''
      install -m644 -D icon.png $out/icon.png
    '';
  };
in
{
  # https://remixicon.com/
  mkIcon = input: "${mkIconDerivation input}/icon.png";
}
