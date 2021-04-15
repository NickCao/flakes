{ qt5
, fetchFromGitHub
, lib
, cmake
, curl
, protobuf
, grpc
, c-ares
, abseil-cpp
, libuv
, re2
, pkg-config
, symlinkJoin
, makeWrapper
, plugins ? [ ]
}:

with qt5;
let
  qv2ray = mkDerivation
    rec {
      pname = "qv2ray";
      version = "2021-04-13";

      src = fetchFromGitHub {
        owner = "Qv2ray";
        repo = "Qv2ray";
        rev = "c2fc5e712b7569a462404fb5cee6d243fef9a873"; # heads/dev
        fetchSubmodules = true;
        sha256 = "07c28cjivxfas7yffard7m03bf0rmm57d8n8q2hfgl3z1wncvp7m";
      };

      cmakeFlags = [
        "-DQV2RAY_DISABLE_AUTO_UPDATE=ON"
        "-DQV2RAY_BUILD_INFO=nixpkgs"
        "-DQV2RAY_DEFAULT_VASSETS_PATH=/run/current-system/sw/share/v2ray"
        "-DQV2RAY_DEFAULT_VCORE_PATH=/run/current-system/sw/bin/v2ray"
        "-DQV2RAY_HAS_BUILT_IN_THEMES=ON"
        "-DUSE_SYSTEM_LIBUV=ON"
      ];

      buildInputs = [ curl protobuf re2 grpc qtbase qttools c-ares abseil-cpp libuv ];
      nativeBuildInputs = [ cmake pkg-config ];

      meta = with lib; {
        description = "A Qt frontend for V2Ray. Written in C++";
        homepage = "https://qv2ray.net";
        license = licenses.gpl3Only;
      };
    };
in
symlinkJoin {
  inherit (qv2ray) name meta;
  paths = [ qv2ray ] ++ plugins;
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/qv2ray --prefix XDG_DATA_DIRS : $out/share
  '';
}
