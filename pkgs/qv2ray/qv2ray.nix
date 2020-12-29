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
  version = "2020-12-23";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "Qv2ray";
    rev = "83797816868ff6a5e0ee76df2875b7cf04f7b6f5"; # dev
    fetchSubmodules = true;
    sha256 = "09zj25adgm2z80l88xnm6aj1anjqp5p3zi7fjb5aw2f56z4ziynn";
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
