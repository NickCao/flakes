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
  version = "unstable-2022-09-26";

  outputs = [ "out" "dev" "postgres" ];

  src = fetchFromGitHub {
    owner = "neondatabase";
    repo = "neon";
    rev = "df45c0d0e57477768097c13c2c3299e634f963b8";
    sha256 = "sha256-W3mP+BJkKq2wOGYsQS2DyNHLVytLuGGMfgquWek0vK4=";
    fetchSubmodules = true;
  };

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    sha256 = "sha256-TrWgr27EIykYiDGYUho9Y9nN/5ShrRTQumQttHbpjH8=";
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
      nodes.machine = { config, pkgs, ... }: {
        environment.systemPackages = with pkgs;[ neondb openssl etcd postgresql_14 ];
        environment.sessionVariables.POSTGRES_DISTRIB_DIR = "${pkgs.neondb.postgres}/v14";
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
