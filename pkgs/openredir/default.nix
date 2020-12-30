{ stdenv, fetchFromGitHub, automake, autoconf, libtool, lua }:
stdenv.mkDerivation rec {
  pname = "openredir";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "lilydjwg";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-aaLbauopSRshV5gvExwkA+9gTzq/Jm7lu4wNHLnGzRI=";
  };

  buildInputs = [ autoconf automake libtool lua ];
  preConfigure = ''
    ./autogen.sh
  '';
}
