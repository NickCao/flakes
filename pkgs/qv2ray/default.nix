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
, symlinkJoin
, makeWrapper
, plugins ? [ ]
}:

with qt5;
let
  qv2ray = mkDerivation
    rec {
      pname = "qv2ray";
      version = "2021-03-06";

      src = fetchFromGitHub {
        owner = "Qv2ray";
        repo = "Qv2ray";
        rev = "14ad1442f363eb066a2cbad99444fd6c8b4504c4"; # heads/dev
        fetchSubmodules = true;
        sha256 = "0w4c69qq85jvz428gl3r7314idbbx2lbi2qy333gg52hyikcfyz1";
      };

      cmakeFlags = [
        "-DQV2RAY_DISABLE_AUTO_UPDATE=ON"
        "-DQV2RAY_BUILD_INFO=nixpkgs"
        # "-DQV2RAY_BUILD_EXTRA_INFO="
        "-DQV2RAY_DEFAULT_VASSETS_PATH=/run/current-system/sw/share/v2ray"
        "-DQV2RAY_DEFAULT_VCORE_PATH=/run/current-system/sw/bin/v2ray"
        "-DQV2RAY_HAS_BUILT_IN_THEMES=ON"
        "-DQV2RAY_EMBED_TRANSLATIONS=ON"
        "-DUSE_SYSTEM_LIBUV=ON"
      ];

      buildInputs = [ curl protobuf grpc qtbase qttools c-ares abseil-cpp libuv ];
      nativeBuildInputs = [ cmake ];

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
