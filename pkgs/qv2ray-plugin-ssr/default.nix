{ qt5, fetchFromGitHub, lib, cmake, libsodium, libuv }:

with qt5;
mkDerivation rec {
  pname = "qv2ray-plugin-ssr";
  version = "3.0.0-pre3";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "QvPlugin-SSR";
    rev = "v${version}";
    fetchSubmodules = true;
    sha256 = "sha256-59g8ykq31SvyAt9joRI0r/xhWWbWPAppeWOLY87WDSM=";
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
  buildInputs = [ libsodium libuv ];

  meta = with lib; {
    description = "ShadowsocksR plugin for Qv2ray";
    homepage = "https://github.com/Qv2ray/QvPlugin-SSR";
    license = licenses.gpl3Only;
  };
}
