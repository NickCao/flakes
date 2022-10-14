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

let
  query = builtins.toFile "query" ''
    CREATE TABLE t(key int primary key, value text);
    INSERT INTO t values(1,1);
    SELECT * FROM t;
  '';
in
stdenv.mkDerivation rec {
  pname = "neondb";
  version = "unstable-2022-10-14";

  outputs = [ "out" "dev" "postgres" ];

  src = fetchFromGitHub {
    owner = "neondatabase";
    repo = "neon";
    rev = "9fe4548e13774d7f1e5f9b5d23e57da971419442";
    sha256 = "sha256-bIUNkkHlD89F9ieewGLKVF8yst+0P3EjROEex4eYSMo=";
    fetchSubmodules = true;
  };

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    sha256 = "sha256-wDd4TYMPkfnORuxmuySEBZZ7d/wVqHslhvBwEWs1fAQ=";
  };

  postPatch = ''
    patchShebangs scripts/ninstall.sh
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

  enableParallelBuilding = true;

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
      name = "neondb";
      nodes.machine = { config, pkgs, ... }: {
        environment.systemPackages = with pkgs;[ neondb openssl etcd postgresql_14 ];
        environment.sessionVariables.POSTGRES_DISTRIB_DIR = "${pkgs.neondb.postgres}";
        users.users.neondb.isSystemUser = true;
        users.users.neondb.group = "nogroup";
      };
      testScript = ''
        machine.wait_for_unit("default.target")
        machine.succeed("sudo -u neondb neon_local init")
        machine.succeed("sudo -u neondb neon_local start")
        machine.succeed("sudo -u neondb neon_local pg start main")
        assert "running" in machine.succeed("sudo -u neondb neon_local pg list")
        machine.succeed("sudo -u neondb psql -p 55432 -h 127.0.0.1 -U cloud_admin postgres -f ${query}")
      '';
    };
  };
}
