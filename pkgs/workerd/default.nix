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
  buildClangBazelPackage = buildBazelPackage.override {
    stdenv = llvmPackages_14.libcxxStdenv;
  };
in
buildClangBazelPackage rec {
  pname = "workerd";
  version = "unstable-2022-09-27";

  bazel = bazel_5;

  nativeBuildInputs = [
    git
  ];

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = pname;
    rev = "8eb4d115b0d0b1d7924e4e217929f2368fc5a913";
    hash = "sha256-jgEo+YRS2B+AFp3KHfEhP41vA8G9tAsb22IQBtcNjyc=";
  };

  removeRulesCC = false;
  dontAddBazelOpts = true;
  bazelTarget = "//src/workerd/server:workerd";
  bazelFlags = [ "-c" "opt" ];

  NIX_CFLAGS_COMPILE = [
    "-isystem ${llvmPackages_14.libcxx.dev}/include/c++/v1"
    "-isystem ${llvmPackages_14.libcxxStdenv.cc}/resource-root/include"
    "-isystem ${glibc.dev}/include"
  ];

  LD_LIBRARY_PATH = lib.makeLibraryPath [ llvmPackages_14.libcxxabi zlib ];

  postPatch = ''
    rm .bazelversion
  '';

  fetchAttrs = {
    preInstall = ''
      find $bazelOut/external/rust_linux_* -executable -type f -exec patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} {} \;
    '';
    sha256 = "sha256-hlG/8DA8wcfVgmJKGWOela9HuV+IUsAE8zKcvHgeTZQ=";
  };

  buildAttrs = {
    installPhase = ''
      runHook preInstall
      install -Dm755 bazel-bin/src/workerd/server/workerd $out/bin/workerd
      runHook postInstall
    '';
  };
}
