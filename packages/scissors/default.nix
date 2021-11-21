{ pkgs, ... }:

with pkgs; stdenv.mkDerivation {
  pname = "scissors";
  version = "1.1";
  buildInputs = [ maim xclip ];
  src = ./.;
  dontBuild = true;
  dontStrip = true;
  dontConfigure = true;
  postPatch = ''
    substituteInPlace scissors.sh \
      --replace "maim" "${maim}/bin/maim" \
      --replace "xclip" "${xclip}/bin/xclip"
  '';
  installPhase = ''
    install -m755 -D scissors.sh $out/bin/scissors
  '';
}
