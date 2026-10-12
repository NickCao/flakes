{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  flex,
  bison,
  readline,
  libssh,
}:

stdenv.mkDerivation {
  pname = "bird-babel-rtt";

  version = "3.3.3-unstable-2026-10-12";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "bird";
    rev = "95dfb71dbf65a0d07308081a9ff773d50f8a8346";
    fetchSubmodules = false;
    hash = "sha256-NSmWVbf7r+O8WlztgNFNVPyl/yW/ALzg8xU0hIF4la0=";
  };

  nativeBuildInputs = [
    autoreconfHook
    flex
    bison
  ];
  buildInputs = [
    readline
    libssh
  ];

  patches = [
    ./dont-create-sysconfdir-2.patch
  ];

  CPP = "${stdenv.cc.targetPrefix}cpp -E";

  configureFlags = [
    "--localstatedir=/var"
    "--runstatedir=/run/bird"
  ];

  meta = with lib; {
    description = "BIRD Internet Routing Daemon";
    homepage = "http://bird.network.cz";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
