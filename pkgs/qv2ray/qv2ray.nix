{ mkDerivation
, fetchFromGitHub
, lib
, cmake
, curl
, protobuf
, grpc
, qtbase
, qttools
, c-ares
, abseil-cpp
}:

mkDerivation rec {
  pname = "qv2ray";
  version = "2020-12-27";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "Qv2ray";
    rev = "ede6abd7662152a9000b97fba5a52a2f47f03e51"; # dev
    fetchSubmodules = true;
    sha256 = "0z2n1bfca60lq9y70rii99w9fz2kfmkpr6nlbjwwwkz5c5sb7fmq";
  };

  cmakeFlags = [
    "-DQV2RAY_DISABLE_AUTO_UPDATE=ON"
    "-DQV2RAY_BUILD_INFO='Qv2ray\\x20Nixpkgs'"
    "-DQV2RAY_DEFAULT_VASSETS_PATH=/run/current-system/sw/share/v2ray"
    "-DQV2RAY_DEFAULT_VCORE_PATH=/run/current-system/sw/bin/v2ray"
    "-DQV2RAY_HAS_BUILT_IN_THEMES=ON"
  ];

  buildInputs = [ curl protobuf grpc qtbase qttools c-ares abseil-cpp ];
  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    description = "使用 Qt 框架的跨平台 V2Ray 客户端";
    homepage = "https://qv2ray.net";
    license = licenses.gpl3Only;
  };
}
