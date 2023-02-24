{ source, lib, stdenv, autoreconfHook, flex, bison, readline, libssh }:

stdenv.mkDerivation {
  inherit (source) pname src;
  version = "unstable-${source.date}";
  nativeBuildInputs = [ autoreconfHook flex bison ];
  buildInputs = [ readline libssh ];

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
