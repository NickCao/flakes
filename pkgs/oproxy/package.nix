{ rustPlatform }:

rustPlatform.buildRustPackage rec {
  name = "oproxy";
  src = ../../fn/oproxy;
  cargoLock = {
    lockFile = src + /Cargo.lock;
  };
}
