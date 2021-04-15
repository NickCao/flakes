{ stdenv, fetchFromGitHub, lib }:

stdenv.mkDerivation rec {
  pname = "smartdns-china-list";
  version = "2021-04-13";

  src = fetchFromGitHub {
    owner = "felixonmars";
    repo = "dnsmasq-china-list";
    rev = "1cdd2f62a7105fccb0c491419af5ffa151315ead"; # heads/master
    sha256 = "0vkb4z3bx5s9bqqqppamrfgc8givc08bjm5q9irzzl8vawd1g495";
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
