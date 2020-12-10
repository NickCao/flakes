{ fetchFromGitHub, fetchurl, buildGoModule, lib }:

let
  geoip = fetchurl {
    url =
      "https://github.com/v2fly/geoip/releases/download/202011260013/geoip.dat";
    sha256 = "sha256-z1cBFjUcnLRlx8KJzYDIb+amNYe7nu0J3CLcRgQShJI=";
  };
  geosite = fetchurl {
    url =
      "https://github.com/v2fly/domain-list-community/releases/download/20201124133241/dlc.dat";
    sha256 = "sha256-bSpp3Hcq0PmcvAksNgXvgN+0B1jiFBxR0iCUSD2cMYo=";
  };
in buildGoModule rec {
  pname = "v2ray-core";
  version = "4.33.0";

  inherit geoip geosite;

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "v2ray-core";
    rev = "v${version}";
    sha256 = "sha256-L8aEQGuOUhDkSPrlDmPh4EtqMP7mFZTquTdaUyIJhxc=";
  };
  vendorSha256 = "sha256-HIjQo170+HGWVdvErjcmin6MYKbEUAAlCIut12ifpUc=";

  buildPhase = ''
    runHook preBuild
    go build -o v2ray v2ray.com/core/main
    runHook postBuild
  '';

  installPhase = ''
    install -Dm755 v2ray -t $out/bin
    install -Dm644 $geoip $out/share/v2ray/geoip.dat
    install -Dm644 $geosite $out/share/v2ray/geosite.dat
  '';

  meta = {
    homepage = "https://www.v2ray.com/";
    description =
      "A platform for building proxies to bypass network restrictions";
    license = with lib.licenses; [ mit unfree ];
  };
}
