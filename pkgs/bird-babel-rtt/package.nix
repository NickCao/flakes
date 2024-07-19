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

  version = "unstable-2024-03-24";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "bird";
    rev = "dac2ce348f5ee321c80d219719118292f027c2d2";
    fetchSubmodules = false;
    sha256 = "sha256-F1UWNwXuISEhhz7BFolUJa7aSKkNpajYH46YqtcknKg=";
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
