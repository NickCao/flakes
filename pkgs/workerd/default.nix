{ lib
, buildBazelPackage
, fetchFromGitHub
, bazel_5
, llvmPackages_14
, git
, stdenv
, zlib
, glibc
}:

let
  stdenv = llvmPackages_14.libcxxStdenv;
  buildClangBazelPackage = buildBazelPackage.override { inherit stdenv; };
in
buildClangBazelPackage rec {
  pname = "workerd";
  version = "unstable-2022-11-04";

  bazel = bazel_5;

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = pname;
    rev = "c6a5a9929df036031a6b5d4d592151850d74d8b1";
    hash = "sha256-BmaE6Iw66AODV9WhXbUOxwyAP799L6ZjQxt//E5cqGw=";
  };

  removeRulesCC = false;
  bazelTarget = "//src/workerd/server:workerd";
  bazelFlags = [ "-c" "opt" ];

  postPatch = ''
    rm .bazelversion
  '';

  fetchAttrs = {
    nativeBuildInputs = [ git ];
    sha256 = "sha256-bj1PYleoXAQ4/ey6Q5lAm+F/8CwwfGoKFxrHduEqpr4=";
  };

  buildAttrs = {
    NIX_CFLAGS_COMPILE = [
      "-Wno-unused-command-line-argument"
      "-Wl,-rpath,${llvmPackages_14.libcxxabi}/lib"
      "-isystem ${llvmPackages_14.libcxx.dev}/include/c++/v1"
      "-isystem ${stdenv.cc}/resource-root/include"
      "-isystem ${glibc.dev}/include"
    ];
    LD_LIBRARY_PATH = lib.makeLibraryPath [ zlib ];
    postConfigure = ''
      find $bazelOut/external/rust_linux_* -executable -type f -exec patchelf \
        --set-interpreter ${stdenv.cc.bintools.dynamicLinker} {} \;
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 bazel-bin/src/workerd/server/workerd $out/bin/workerd
      runHook postInstall
    '';
  };
}
