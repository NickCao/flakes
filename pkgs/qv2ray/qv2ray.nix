{ mkDerivation, fetchFromGitHub, lib, cmake, curl, protobuf, grpc, qtbase
, qttools, c-ares, abseil-cpp }:

mkDerivation rec {
  pname = "qv2ray";
  version = "2.7.0-pre1";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "Qv2ray";
    rev = "2e8ee77";
    fetchSubmodules = true;
    sha256 = "sha256-ioI6nLnbT/7BOTCs/qz4qr519HlO0j3xL4CKFajAxzo=";
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
