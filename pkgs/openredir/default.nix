{ stdenv, fetchFromGitHub, automake, autoconf, libtool, lua, lib }:
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

  meta = with lib; {
    homepage = "https://github.com/lilydjwg/openredir";
    description = "redirect file open operations via LD_PRELOAD";
    license = licenses.bsd2;
  };
}
