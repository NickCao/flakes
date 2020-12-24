{ stdenv, fetchFromGitHub, lib }:

stdenv.mkDerivation rec {
  pname = "smartdns-china-list";
  version = "2020-12-24";

  src = fetchFromGitHub {
    owner = "felixonmars";
    repo = "dnsmasq-china-list";
    rev = "fd9d527a1d4ebfec010bd8bf3489f6bb12d22a17"; # heads/master
    sha256 = "0lqgdr7d2qqnn8fa1vq85zzaiin9hldhx90288hj6fiparpaifs0";
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
