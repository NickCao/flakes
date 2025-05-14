{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, flex
, bison
, readline
, libssh
,
}:

stdenv.mkDerivation {
  pname = "bird-babel-rtt";

  version = "0-unstable-2025-05-16";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "bird";
    rev = "5567bdd85c0e8cbcd69122ae93909ee4e23c0f21";
    fetchSubmodules = false;
    sha256 = "sha256-ILPOAv0onWDrOEYLzI+GzChvKcTqDliIRCUC+YPEPZg=";
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

  patches = [ ./dont-create-sysconfdir-2.patch ];

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
