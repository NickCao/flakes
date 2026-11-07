{
  rustPlatform,
  pkg-config,
  aws-lc,
}:

rustPlatform.buildRustPackage rec {
  name = "oproxy";

  src = ../../fn/oproxy;

  cargoLock = {
    lockFile = src + /Cargo.lock;
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    aws-lc
  ];
}
