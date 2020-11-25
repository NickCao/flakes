{ mkDerivation, fetchFromGitHub, lib, cmake, curl, protobuf, grpc, qtbase
, qttools, c-ares, abseil-cpp }:

mkDerivation rec {
  pname = "qv2ray";
  version = "2.7.0-pre1";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "Qv2ray";
    rev = "v${version}";
    fetchSubmodules = true;
    sha256 = "P1ObRtbRpf3i1d0n/t24Zam5SFXLmZ1p2B5oKkP8USA=";
  };

  buildInputs = [ curl protobuf grpc qtbase qttools c-ares abseil-cpp ];
  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    description = "使用 Qt 框架的跨平台 V2Ray 客户端";
    homepage = "https://qv2ray.net";
    license = licenses.gpl3Only;
  };
}
