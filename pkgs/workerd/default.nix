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
  version = "unstable-2022-09-27";

  bazel = bazel_5;

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = pname;
    rev = "8eb4d115b0d0b1d7924e4e217929f2368fc5a913";
    hash = "sha256-jgEo+YRS2B+AFp3KHfEhP41vA8G9tAsb22IQBtcNjyc=";
  };

  removeRulesCC = false;
  bazelTarget = "//src/workerd/server:workerd";
  bazelFlags = [ "-c" "opt" ];

  postPatch = ''
    rm .bazelversion
  '';

  fetchAttrs = {
    nativeBuildInputs = [ git ];
    sha256 = "sha256-0x4OZ6BLXNhCT21xqfAGvsEjUUgXiYpf64wGIvzl9bc=";
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
