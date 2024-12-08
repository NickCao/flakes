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

  version = "0-unstable-2024-12-08";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "bird";
    rev = "847dc444973ef16b0f3ed24660d010f1dd057589";
    fetchSubmodules = false;
    sha256 = "sha256-+dOnj8RbZnpnDzyC51cmaLCD48xac72bRbttDCRLLqA=";
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
