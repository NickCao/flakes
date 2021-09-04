{ qt5, fetchurl, dpkg, autoPatchelfHook, xorg, libbsd }:
qt5.mkDerivation {
  pname = "wemeet";
  version = "2.8.0.0";
  src = fetchurl {
    url = "https://updatecdn.meeting.qq.com/ad878a99-76c4-4058-ae83-22ee948cce98/TencentMeeting_0300000000_2.8.0.0_x86_64.publish.deb";
    sha256 = "sha256-prNQawKHAZZpTxODVMzOb6qB44oZok46OzQmyLJO/L8=";
  };
  nativeBuildInputs = [ dpkg autoPatchelfHook ];
  autoPatchelfIgnoreMissingDeps=true;
  buildInputs = [
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXdamage
    qt5.qtwebkit
    qt5.qtx11extras
    libbsd
  ];
  dontUnpack = true;
  installPhase = ''
    dpkg-deb -x $src .
    mkdir $out
    mv opt/wemeet/bin $out/bin
    mkdir $out/lib
    mv opt/wemeet/lib/libwemeet*.so $out/lib
    mv opt/wemeet/lib/libxnn*.so $out/lib
    mv opt/wemeet/lib/libxcast.so $out/lib
    mv opt/wemeet/lib/libtquic.so $out/lib
  '';
}
