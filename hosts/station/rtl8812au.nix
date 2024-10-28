{ pkgs
, lib
, fetchFromGitHub
, kernel ? pkgs.linuxPackages_latest.kernel
}:

let 
  modulePath = "$out/lib/modules/${kernel.modDirVersion}/kernel/net/wireless/";
in
pkgs.stdenv.mkDerivation rec {
  name = "rtl8812au";
  version = "5.6.4.2";

  src = fetchFromGitHub {
    owner = "aircrack-ng";
    repo = "rtl8812au";
    rev = "v${version}";
    sha256 = "sha256-JCvFin8iPXS1Qgd9LxPDcP21pfbPiQZbWTBeqvPHGFA=";
  };

  hardeningDisable = [ "pic" "format" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;
  makeFlags = kernel.makeFlags;

  prePatch = ''
    substituteInPlace ./Makefile \
      --replace /lib/modules/ "${kernel.dev}/lib/modules/" \
      --replace /sbin/depmod \# \
      --replace '$(MODDESTDIR)' "${modulePath}"
  '';

   preInstall = ''
    mkdir -p "$out/lib/modules/${kernel.modDirVersion}/kernel/net/wireless/"
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "RTL8812AU/21AU and RTL8814AU driver with monitor mode and frame injection ";
    homepage = "https://github.com/aircrack-ng/rtl8812au";
    platforms = platforms.linux;
  };
}
