{ stdenv
, lib
, dpkg
, fetchurl
, makeWrapper
, xar
, cpio
  # Dynamic libraries
, alsa-lib
, atk
, at-spi2-atk
, at-spi2-core
, cairo
, cups
, dbus
, expat
, libdrm
, libGL
, fontconfig
, freetype
, gtk3
, gdk-pixbuf
, glib
, mesa
, nspr
, nss
, pango
, wayland
, xorg
, libxkbcommon
, udev
, zlib
  # Runtime
, coreutils
, pciutils
, procps
, util-linux
, libpulseaudio
}:

let
  libs = lib.makeLibraryPath ([
    alsa-lib
    atk
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    libdrm
    libGL
    fontconfig
    freetype
    gtk3
    gdk-pixbuf
    glib
    mesa
    nspr
    nss
    pango
    stdenv.cc.cc
    wayland
    xorg.libX11
    xorg.libxcb
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    libxkbcommon
    xorg.libXrandr
    xorg.libXrender
    xorg.libxshmfence
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.libXfixes
    xorg.libXtst
    udev
    zlib
    libpulseaudio
  ]);
in
stdenv.mkDerivation rec {
  pname = "zhumuintl";
  version = "2022-07-03";

  src = fetchurl {
    url = "https://d.zhumu.com/client/latest/zhumuintl_amd64.deb";
    sha256 = "sha256-9eEF5XijNShGvMP3Nrxye+3OIr4+0WwsNDOdnm6Y88o=";
  };

  dontUnpack = true;
  nativeBuildInputs = [
    dpkg
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall
    dpkg-deb -x $src $out
    chmod 0755 $out
    mv $out/usr/* $out/
    runHook postInstall
  '';

  postFixup = ''
    substituteInPlace $out/share/applications/zhumuintl.desktop \
        --replace "Exec=/usr/bin/zhumuintl" "Exec=$out/bin/zhumuintl"

    for i in zopen zhumuintl zhumuintlLauncher; do
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/opt/zhumuintl/$i
    done

    mv $out/opt/zhumuintl/zhumuintl $out/opt/zhumuintl/.zhumuintl
    makeWrapper $out/opt/zhumuintl/.zhumuintl $out/opt/zhumuintl/zhumuintl \
      --prefix LD_LIBRARY_PATH ":" ${libs}

    rm $out/bin/zhumuintl
    makeWrapper $out/opt/zhumuintl/zhumuintlLauncher $out/bin/zhumuintl \
      --chdir "$out/opt/zhumuintl" \
      --unset QML2_IMPORT_PATH \
      --unset QT_PLUGIN_PATH \
      --unset QT_SCREEN_SCALE_FACTORS \
      --prefix PATH : ${lib.makeBinPath [ coreutils glib.dev pciutils procps util-linux ]} \
      --prefix LD_LIBRARY_PATH ":" ${libs}
  '';

  dontPatchELF = true;

  meta = with lib; {
    homepage = "https://zhumu.com";
    description = "zhumu.com video conferencing application";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
  };
}
