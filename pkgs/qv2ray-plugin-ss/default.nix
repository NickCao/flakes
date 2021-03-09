{ qt5, fetchFromGitHub, lib, cmake, libsodium, libuv, mbedtls }:

with qt5;
mkDerivation rec {
  pname = "qv2ray-plugin-ss";
  version = "2020-12-14";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "QvPlugin-SS";
    rev = "b8a497ed610b968eab0dc0a47e87ded63a2d64a9"; # heads/dev
    fetchSubmodules = true;
    sha256 = "1acnqvfwgxjn2d3gbbkd3dp1vw7j53a7flwwn4mn93l9y6y0n72r";
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
  buildInputs = [ libuv libsodium mbedtls ];

  meta = with lib; {
    description = "Shadowsocks plugin for Qv2ray";
    homepage = "https://github.com/Qv2ray/QvPlugin-SS";
    license = licenses.gpl3Only;
  };
}
