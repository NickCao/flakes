{ qt5, fetchFromGitHub, lib, cmake, libsodium, libuv }:

with qt5;
mkDerivation rec {
  pname = "qv2ray-plugin-ss";
  version = "3.0.0-pre3";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "QvPlugin-SS";
    rev = "v${version}";
    fetchSubmodules = true;
    sha256 = "sha256-oHzSyKLaPyub+5bOaOfXWhPJjLvSABa9py9s6WYqjpM=";
  };

  cmakeFlags = [
    "-DUSE_SYSTEM_SODIUM=ON"
    "-DUSE_SYSTEM_LIBUV=ON"
    "-DLibUV_LIBRARY=${libuv}/lib/libuv.so"
    # workaroud for badly written cmake
    "-DQV_QT_MAJOR_VERSION=5"
    "-DQV_QT_MINOR_VERSION=0"
  ];

  nativeBuildInputs = [ cmake ];
  buildInputs = [ libuv libsodium ];

  meta = with lib; {
    description = "Shadowsocks plugin for Qv2ray";
    homepage = "https://github.com/Qv2ray/QvPlugin-SS";
    license = licenses.gpl3Only;
  };
}
