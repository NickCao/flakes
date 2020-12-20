{ fetchurl, stdenv }:

stdenv.mkDerivation {
  name = "v2ray-assets";
  srcs = [
    (fetchurl {
      url =
        "https://github.com/v2fly/geoip/releases/download/202012170018/geoip.dat";
      sha256 = "sha256-WflraAHhGVHjavkk1CCXJi/fCP/bz7lYDhLvXSfAFcs=";
    })
    (fetchurl {
      url =
        "https://github.com/v2fly/domain-list-community/releases/download/20201220111409/dlc.dat";
      sha256 = "sha256-jhzu5PKxQcr//tIXp0vxZ7Y0I8oB9lqnTi4xtybWPWI=";
    })
  ];

  unpackCmd = ''
    install -m 0644 $curSrc -D src/''${curSrc#*-}
  '';

  installPhase = ''
    install -m 0644 geoip.dat -D $out/share/v2ray/geoip.dat
    install -m 0644 dlc.dat -D $out/share/v2ray/geosite.dat
  '';
}
