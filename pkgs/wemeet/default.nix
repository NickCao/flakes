{ source, qt5, dpkg, autoPatchelfHook, libbsd, makeWrapper }:
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
    mv opt/wemeet/lib/lib{ImSDK,desktop_common,nxui*,qt_*,ui*,wemeet*,xcast,xcast_codec,xnn*}.so $out/lib
    wrapQtApp "$out/bin/wemeetapp" \
      --set PULSE_LATENCY_MSEC 20
  '';
  meta = {
    mainProgram = "wemeetapp";
    platforms = [ "x86_64-linux" ];
  };
}
