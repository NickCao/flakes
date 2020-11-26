{ mkDerivation, fetchFromGitHub, symlinkJoin, lib, cmake, curl, protobuf, grpc, qtbase
, qttools, c-ares, abseil-cpp, enableSSR ? true }:

let

unwrapped = mkDerivation rec {
  pname = "qv2ray";
  version = "2.7.0-pre1-7b04b83";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "Qv2ray";
    rev = "7b04b83";
    fetchSubmodules = true;
    sha256 = "sha256-KCDorY/jytumjI1Kp9HZHeb3SNSECwK0Sbll9K876xg=";
  };

  cmakeFlags = [
    "-DQV2RAY_DISABLE_AUTO_UPDATE=ON"
    #"-DQV2RAY_BUILD_INFO='Qv2ray Nixpkgs'"
    #"-DQV2RAY_BUILD_EXTRA_INFO='(Nixpkgs build) nixpkgs'"
    "-DQV2RAY_HAS_BUILT_IN_THEMES=ON"
    "-DEMBED_TRANSLATIONS=ON"
  ];

  buildInputs = [ curl protobuf grpc qtbase qttools c-ares abseil-cpp ];
  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    description = "使用 Qt 框架的跨平台 V2Ray 客户端";
    homepage = "https://qv2ray.net";
    license = licenses.gpl3Only;
  };
};

ssr = import ./plugins/ssr.nix {
  inherit mkDerivation fetchFromGitHub lib cmake;
};

plugins = [ ssr ];

in
  symlinkJoin {
    name = unwrapped.name;
    paths = [ unwrapped ] ++ plugins;
  }
