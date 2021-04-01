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
      version = "2021-03-31";

      src = fetchFromGitHub {
        owner = "Qv2ray";
        repo = "Qv2ray";
        rev = "2873f46175cb696d382c5c16bf4e35fda042c612"; # heads/dev
        fetchSubmodules = true;
        sha256 = "0maabclgny0mnbca94p9cx4i3d32b1yhr1lih45dygzbm31fd83w";
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
