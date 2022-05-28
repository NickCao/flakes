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
  pname = "neon";
  version = "unstable-2022-08-20";

  outputs = [ "out" "dev" "postgres" ];

  src = fetchFromGitHub {
    owner = "neondatabase";
    repo = "neon";
    rev = "5522fbab25f1cd7cfaa36cf674e462172f24eff8";
    sha256 = "sha256-NursmTPnGlH8GJ6fYIDqpEFVt72u/wa4Kyvb9x3RW4s=";
    fetchSubmodules = true;
  };

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    sha256 = "sha256-FeDDEJPK2lAtpmv3NI7W8qjdkuiaQ87S62NK01fAIvE=";
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
