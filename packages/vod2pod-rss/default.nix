{ pkgs, ... }:

with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "vod2pod-rss";
  version = "more-conf";

  src = fetchFromGitHub {
    owner = "barsoosayque";
    repo = pname;
    rev = version;
    sha256 = "sha256-tX4vyqmGSxI3uug+wz94pKcsK+KXfyYs/ho0fNl70Ow=";
  };

  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
  '';
  cargoLock = {
    lockFile = ./Cargo.lock;
    allowBuiltinFetchGit = true;
  };

  checkType = "release";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
    perl
    makeWrapper
  ];

  postInstall = ''
    mkdir -p $out/share/vod2pod-rss
    cp -r $src/templates $out/share/vod2pod-rss/

    wrapProgram $out/bin/app \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg yt-dlp ]}
  '';

  meta = {
    description = "Vod2Pod-RSS converts a YouTube or Twitch channel into a podcast with ease. It creates a podcast RSS that can be listened to directly inside any podcast client. VODs are transcoded to MP3 on the fly and no server storage is needed!";
    homepage = "https://github.com/${owner}/${repo}";
    platforms = lib.platforms.unix;
  };
}
