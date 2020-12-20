{ fetchurl, stdenv }:

stdenv.mkDerivation {
  pname = "v2ray-assets";
  version = "";
  srcs = [
    (fetchurl {
      url =
        "https://github.com/v2fly/geoip/releases/download/202011260013/geoip.dat";
      sha256 = "sha256-z1cBFjUcnLRlx8KJzYDIb+amNYe7nu0J3CLcRgQShJI=";
    })
    (fetchurl {
      url =
        "https://github.com/v2fly/domain-list-community/releases/download/20201124133241/dlc.dat";
      sha256 = "sha256-bSpp3Hcq0PmcvAksNgXvgN+0B1jiFBxR0iCUSD2cMYo=";
    })
  ];

  phases = [ "installPhase" ];
  installPhase = ''
    export
    for file in $srcs; do
      install -m 0644 $file -D $out/share/v2ray/''${file#*-}
    done
  '';
}
