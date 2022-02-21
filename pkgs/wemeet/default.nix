{ source, qt5, fetchurl, dpkg, autoPatchelfHook, xorg, libbsd }:
qt5.mkDerivation {
  inherit (source) pname version src;
  nativeBuildInputs = [ dpkg autoPatchelfHook ];
  autoPatchelfIgnoreMissingDeps = true;
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
    mv opt/wemeet/lib/{libwemeet*,libxcast.so,libxnn*,libtquic.so} $out/lib
    mkdir $out/share
    mv opt/wemeet/icons $out/share
  '';
  meta = {
    mainProgram = "wemeetapp";
    platforms = [ "x86_64-linux" ];
  };
}
