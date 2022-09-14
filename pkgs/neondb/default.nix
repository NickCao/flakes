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
, nixosTest
}:

stdenv.mkDerivation rec {
  pname = "neondb";
  version = "unstable-2022-09-14";

  outputs = [ "out" "dev" "postgres" ];

  src = fetchFromGitHub {
    owner = "neondatabase";
    repo = "neon";
    rev = "c3096532f9ceee8fad82b4c741b0108bd143cc06";
    sha256 = "sha256-ZTRkys5Q9c98fQBiUyG61lXV5k/nFqm/IjAkvHKC/6w=";
    fetchSubmodules = true;
  };

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    sha256 = "sha256-mTJj5IkPR62AlxACA/zOS68+yfUwDx9Xty7Z1Xh6w2c=";
  };

  postPatch = ''
    substituteInPlace vendor/postgres-*/configure --replace  "/bin/pwd" "pwd"
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

  passthru.tests = {
    basic = nixosTest {
      nodes.machine = { config, pkgs, ... }: {
        environment.systemPackages = with pkgs;[ neondb openssl etcd ];
        environment.sessionVariables.POSTGRES_DISTRIB_DIR = pkgs.neondb.postgres.outPath;
        users.users.neondb.isSystemUser = true;
        users.users.neondb.group = "nogroup";
      };
      testScript = ''
        machine.wait_for_unit("default.target")
        machine.succeed("sudo -u neondb neon_local init")
        machine.succeed("sudo -u neondb neon_local start")
        machine.succeed("sudo -u neondb neon_local pg start main")
        assert "running" in machine.succeed("sudo -u neondb neon_local pg list")
      '';
    };
  };
}
