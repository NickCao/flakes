{ stdenv, fetchFromGitHub, lib }:

stdenv.mkDerivation rec {
  pname = "smartdns-china-list";
  version = "2021-04-20";

  src = fetchFromGitHub {
    owner = "felixonmars";
    repo = "dnsmasq-china-list";
    rev = "585be8e77ed3097b9af8bc3ec33d19c55769a4bc"; # heads/master
    sha256 = "0lf2ih8d4pwcxmniizfhx68m5jlyry55in560ppbvm3yph9h0amn";
  };

  buildPhase = ''
    make smartdns SERVER=china
  '';

  installPhase = ''
    install -Dm644 "accelerated-domains.china.smartdns.conf" "$out/accelerated-domains.china.smartdns.conf"
    install -Dm644 "apple.china.smartdns.conf" "$out/apple.china.smartdns.conf"
    install -Dm644 "google.china.smartdns.conf" "$out/google.china.smartdns.conf"
  '';

  meta = with lib; {
    description =
      "Chinese-specific configuration to improve your favorite DNS server. Best partner for chnroutes.";
    homepage = "https://github.com/felixonmars/dnsmasq-china-list";
    license = licenses.wtfpl;
  };
}
