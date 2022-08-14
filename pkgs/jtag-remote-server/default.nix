{ source, stdenv, cmake, pkg-config, libftdi1 }:

stdenv.mkDerivation rec {
  inherit (source) pname version src;
  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libftdi1 ];
  installPhase = ''
    install -Dm755 jtag-remote-server $out/bin/jtag-remote-server
  '';
}
