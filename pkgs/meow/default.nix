{ rustPlatform }:

rustPlatform.buildRustPackage rec {
  name = "meow";
  src = ../../fn/meow;
  cargoLock = {
    lockFile = src + /Cargo.lock;
  };
}
