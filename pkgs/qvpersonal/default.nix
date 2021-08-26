{ gcc11Stdenv
, lib
, fetchurl
, autoPatchelfHook
, zstd
, libnsl
, libdrm
, libudev
, libinput
, libjpeg
, xorg
, double-conversion
, harfbuzz
, icu
, pcre2
, libGL
, libxkbcommon
, fontconfig
, brotli
, libb2
, glib
, mesa
, tslib
}:
gcc11Stdenv.mkDerivation rec {
  pname = "qvpersonal";
  version = "2021-08-25";
  src = fetchurl {
    url = "https://github.com/Shadowsocks-NET/QvStaticBuild/releases/download/nightly-${version}/qv2ray-static-bin-nightly-${version}-archlinux-x86_64.tar.zst";
    sha256 = "sha256-5MTfu8TYUp6h8U0ux941qJetZMrmaWpI/NK5Kfvb8fU";
  };
  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook zstd ];
  buildInputs = [
    gcc11Stdenv.cc.cc.lib
    tslib
    mesa
    xorg.libSM
    xorg.libICE
    glib
    xorg.xcbutilwm
    xorg.xcbutilkeysyms
    libb2
    brotli
    fontconfig
    xorg.xcbutilrenderutil
    xorg.xcbutilimage
    libxkbcommon
    libnsl
    libdrm
    libudev
    libinput
    (libjpeg.override { enableJpeg8 = true; })
    double-conversion
    harfbuzz
    icu
    pcre2
    libGL
    xorg.libxcb
    xorg.libX11
  ];
  installPhase = ''
    mkdir $out
    tar -x -f $src -C $out
  '';
  meta = with lib; {
    description = "A cross-platform Qt frontend for V2Ray";
    homepage = "https://github.com/moodyhunter/QvPersonal";
    license = licenses.gpl3Only;
  };
}
