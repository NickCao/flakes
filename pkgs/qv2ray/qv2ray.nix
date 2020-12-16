{ mkDerivation, fetchFromGitHub, lib, cmake, curl, protobuf, grpc, qtbase
, qttools, c-ares, abseil-cpp }:

mkDerivation rec {
  pname = "qv2ray";
  version = "2.7.0-git";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "Qv2ray";
    rev = "699ec5e62ab52b6ce6b8200663967cd0d4f67413";
    fetchSubmodules = true;
    sha256 = "sha256-mBxsk9ZB97+0o5Vx/BZ5HnsvJFDCy9PGTzb0kffmbk4=";
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
