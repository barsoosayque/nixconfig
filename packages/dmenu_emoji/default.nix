{ pkgs, ... }:

let
  inherit (pkgs) fetchurl;
  inherit (pkgs.stdenv) mkDerivation;
  inherit (builtins) concatStringsSep;
in mkDerivation rec {
  pname = "dmenu_emoji";
  version = "1.0";

  cldrVersion = "40.0.0";
  
  buildInputs = [ pkgs.jq pkgs.makeWrapper ];
  runtimeInputs = [ pkgs.dmenu ];

  src = fetchGit {
      url = "https://github.com/unicode-org/cldr-json.git";
      ref = "refs/tags/${cldrVersion}";
      rev = "30a47d99cbd6514d9ca6d667d3ec94656081e660";
  };

  buildPhase = let 
    jqFormula = concatStringsSep " | " [
      ''.annotations.annotations''
      ''[keys_unsorted, map(.default | join(" | "))]''
      ''transpose''
      ''map("\(.[0]) (\(.[1]))")''
      ''join("\n")''
    ];
  in ''
    jq -jr '${jqFormula}' \
      cldr-json/cldr-annotations-full/annotations/en/annotations.json > emoji-data

    cat <<EOF > dmenu_emoji.sh
      #!${pkgs.dash}/bin/dash
      cat \$EMOJI_FILE | dmenu \$@
    EOF
  '';

  installPhase = ''
    install -m644 -D emoji-data $out/emoji-data
    install -m755 -D dmenu_emoji.sh $out/bin/${pname}
    wrapProgram $out/bin/${pname} --set EMOJI_FILE $out/emoji-data
  '';
}
