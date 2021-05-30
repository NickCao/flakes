{ source, qt5, fetchFromGitHub, lib, cmake, libsodium, libuv, mbedtls }:

with qt5;
mkDerivation rec {
  inherit (source) pname version src;

  cmakeFlags = [
    "-DUSE_SYSTEM_SODIUM=ON"
    "-DUSE_SYSTEM_LIBUV=ON"
    "-DLibUV_LIBRARY=${libuv}/lib/libuv.so"
    # workaroud for badly written cmake
    "-DQV_QT_MAJOR_VERSION=5"
    "-DQV_QT_MINOR_VERSION=0"
  ];

  nativeBuildInputs = [ cmake ];
  buildInputs = [ libuv libsodium mbedtls ];

  meta = with lib; {
    description = "Shadowsocks plugin for Qv2ray";
    homepage = "https://github.com/Qv2ray/QvPlugin-SS";
    license = licenses.gpl3Only;
  };
}
