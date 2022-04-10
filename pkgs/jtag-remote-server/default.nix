{ stdenv, fetchFromGitHub, cmake, pkg-config, libftdi1 }:

stdenv.mkDerivation rec {
  pname = "jtag-remote-server";
  version = "c27836164d6d3a5728666c6ebff3395cc7b194cc";

  src = fetchFromGitHub {
    owner = "jiegec";
    repo = pname;
    rev = version;
    sha256 = "sha256-abHHMlhRyYwCKVQsZNIwbvC3oKdIIOAda3wuZ/ecl4c=";
  };
  patches = [ ./unmatched.patch ];

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libftdi1 ];

  installPhase = ''
    install -Dm755 jtag-remote-server $out/bin/jtag-remote-server
  '';
}
