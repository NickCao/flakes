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

  version = "0-unstable-2026-04-05";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "bird";
    rev = "1a4d4a81b3e3ca23edad75c027dc3e19ef1947b8";
    fetchSubmodules = false;
    sha256 = "sha256-CC3rLrhnCAcFYwbOK2pGpHVCZvyD9tCkJacXMQU/lX4=";
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
