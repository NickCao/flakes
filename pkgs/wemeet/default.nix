{ source, qt5, fetchurl, dpkg, autoPatchelfHook, xorg, libbsd, makeWrapper }:
qt5.mkDerivation {
  inherit (source) pname version src;
  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];
  buildInputs = [
    qt5.qtx11extras
    qt5.qtwebengine
    libbsd
  ];
  dontUnpack = true;
  dontWrapQtApps = true;
  installPhase = ''
    dpkg-deb -x $src .
    mkdir -p $out/{bin,lib}
    mv opt/wemeet/bin/{wemeetapp,raw,modules,wemeet.res,manifest.json,qt_zh_CN.qm} $out/bin
    mv opt/wemeet/lib/{libwemeet*,libxnn*,libxcast*,libImSDK.so,libdesktop_common.so,libnxui_uikit.so,libui_framework.so} $out/lib
    wrapQtApp "$out/bin/wemeetapp" \
      --set XDG_SESSION_TYPE  x11  \
      --set PULSE_LATENCY_MSEC 20
  '';
  meta = {
    mainProgram = "wemeetapp";
    platforms = [ "x86_64-linux" ];
  };
}
