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

  version = "0-unstable-2025-04-09";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "bird";
    rev = "6de40f71bb4b574918a9f5ba67127cfd415318dd";
    fetchSubmodules = false;
    sha256 = "sha256-2ZuSUnSWBhMMhh7J3edqhiqbtkNiIEqTd/4PX9dXLy8=";
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
