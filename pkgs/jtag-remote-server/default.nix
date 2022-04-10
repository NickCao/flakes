{ stdenv, fetchFromGitHub, cmake, pkg-config, libftdi1 }:

stdenv.mkDerivation rec {
  pname = "jtag-remote-server";
  version = "56080ee9e5a3d55eb7cf3382cc42f713d69e1f75";

  src = fetchFromGitHub {
    owner = "jiegec";
    repo = pname;
    rev = version;
    sha256 = "sha256-AYiFd92qpB+9SOZAwAswQYbOndDTiAGZReHwZxJgvF0=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libftdi1 ];

  installPhase = ''
    install -Dm755 jtag-remote-server $out/bin/jtag-remote-server
  '';
}
