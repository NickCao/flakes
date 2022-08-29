{ stdenv
, fetchFromGitHub
, perl
, flex
, bison
, pkg-config
, cmake
, readline
, zlib
, openssl
, libseccomp
, rustPlatform
, buildType ? "release"
}:

stdenv.mkDerivation rec {
  pname = "neondb";
  version = "unstable-2022-08-29";

  outputs = [ "out" "dev" "postgres" ];

  src = fetchFromGitHub {
    owner = "neondatabase";
    repo = "neon";
    rev = "1324dd89ed612e709fc8c84206d0a32936382789";
    sha256 = "sha256-KuXWZxryd7+2SW3eYG91vvKg/Che0CIEk8WKh/Ffe/8=";
    fetchSubmodules = true;
  };

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    sha256 = "sha256-f9u8Rmj1CF8EWGMu9KGBGZHTm9qWWL4M5GRurKwG7YU=";
  };

  postPatch = ''
    substituteInPlace vendor/postgres/configure --replace  "/bin/pwd" "pwd"
    substituteInPlace libs/postgres_ffi/build.rs --replace '.join("postgresql")' ""
  '';

  nativeBuildInputs = [ perl flex bison pkg-config cmake ] ++ (with rustPlatform; [
    cargoSetupHook
    bindgenHook
    rust.cargo
    rust.rustc
  ]);

  buildInputs = [ readline zlib openssl libseccomp ];

  dontUseCmakeConfigure = true;

  GIT_VERSION = version;
  BUILD_TYPE = buildType;
  POSTGRES_INSTALL_DIR = placeholder "postgres";

  installPhase = ''
    runHook preBuild
    rm -r "$postgres/build"
    (
      cd target/${buildType}
      find . -maxdepth 1 -executable -type f -exec install -Dm755 {} $out/bin/{} \;
    )
    runHook postBuild
  '';
}
