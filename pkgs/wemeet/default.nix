{ source, qt5, fetchurl, dpkg, autoPatchelfHook, xorg, libbsd, makeWrapper }:
qt5.mkDerivation {
  inherit (source) pname version src;
  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];
  buildInputs = [
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXdamage
    qt5.qtwebkit
    qt5.qtx11extras
    libbsd
  ];
  autoPatchelfIgnoreMissingDeps = [
    "libcudart.so.9.0"
    "libcudnn.so.7"
    "libnvinfer.so.5"
    "libnvinfer_plugin.so.5"
  ];
  dontUnpack = true;
  installPhase = ''
    dpkg-deb -x $src .
    mkdir $out
    mv opt/wemeet/bin $out/bin
    mkdir $out/lib
    mv opt/wemeet/lib/{libwemeet*,libxcast.so,libxnn*,libtquic.so} $out/lib
    mkdir $out/share
    mv opt/wemeet/icons $out/share
    wrapProgram $out/bin/wemeetapp \
      --set XDG_SESSION_TYPE x11 \
      --unset WAYLAND_DISPLAY
  '';
  meta = {
    mainProgram = "wemeetapp";
    platforms = [ "x86_64-linux" ];
  };
}
