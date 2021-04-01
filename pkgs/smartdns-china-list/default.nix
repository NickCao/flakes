{ stdenv, fetchFromGitHub, lib }:

stdenv.mkDerivation rec {
  pname = "smartdns-china-list";
  version = "2021-03-31";

  src = fetchFromGitHub {
    owner = "felixonmars";
    repo = "dnsmasq-china-list";
    rev = "3a83326d58087417ea18aa431f2aed3176696160"; # heads/master
    sha256 = "11l526r94dck8j9k3p8qlsb241sgj52cf0pl94xzvlns569v4w1r";
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
