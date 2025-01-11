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

  version = "0-unstable-2025-01-11";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "bird";
    rev = "700a4fddd3b554cc1071608cf8d945400ae35c9e";
    fetchSubmodules = false;
    sha256 = "sha256-f6L/6S+GYCKVC5Pgj0TLD9R5C5+nj4Aczu8ztmWswCk=";
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
