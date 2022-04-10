{ stdenv, fetchFromGitHub, cmake, pkg-config, libftdi1 }:

stdenv.mkDerivation rec {
  pname = "jtag-remote-server";
  version = "9d0bbcd758c7078ae143716544d9bd184e3d7423";

  src = fetchFromGitHub {
    owner = "jiegec";
    repo = pname;
    rev = version;
    sha256 = "sha256-DX4/v0jrDfthBv6LuvGWMXAZLkENOgC85L1Qx2yWdrE=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libftdi1 ];

  installPhase = ''
    install -Dm755 jtag-remote-server $out/bin/jtag-remote-server
  '';
}
