{ source, stdenv, rustPlatform, lib, git, cargo }:
stdenv.mkDerivation {
  inherit (source) pname version src;
  nativeBuildInputs = [ git cargo rustPlatform.cargoSetupHook ];
  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit (source) src;
    hash = "";
  };
  meta = with lib; {
    description = "an open-source, distributed, and transactional key-value database";
    homepage = "https://tikv.org";
    license = licenses.asl20;
  };
}
