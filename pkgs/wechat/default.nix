{ stdenv, fetchurl, autoPatchelfHook, libarchive, nss, xorg, gtk2, gnome2, alsaLib, pulseaudio }:
stdenv.mkDerivation rec {
  pname = "wechat";
  version = "2.0.0";

  src = fetchurl {
    url = "https://cdn-package-store6.deepin.com/appstore/pool/appstore/c/com.qq.weixin/com.qq.weixin_${version}_amd64.deb";
    sha256 = "0l5i3nvl241y4cwwv733b170bjqfipybm7ky277bhkm49jph808b";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = with xorg;[
    libarchive
    libXtst
    libXScrnSaver
    libXdamage
    gtk2
    nss
    gnome2.GConf
    alsaLib
  ];

  runtimeDependencies = [ pulseaudio ];

  unpackPhase = ''
    bsdtar -O -f $src -x data.tar.xz | bsdtar -f - -x
  '';

  installPhase = ''
    mkdir -p $out
    mv opt usr $out
  '';
}
