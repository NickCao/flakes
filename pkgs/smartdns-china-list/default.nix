{ stdenv, fetchFromGitHub, lib }:

stdenv.mkDerivation rec {
  pname = "smartdns-china-list";
  version = "2021-03-14";

  src = fetchFromGitHub {
    owner = "felixonmars";
    repo = "dnsmasq-china-list";
    rev = "c3688fe98c686e5e462eaa7f38c1d4750b2dab51"; # heads/master
    sha256 = "0zsqahxmy8dslpmd6n6p1qr8axpf18bw36zlby562qhr5sbxy233";
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
