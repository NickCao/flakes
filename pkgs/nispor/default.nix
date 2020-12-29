{ fetchFromGitHub, rustPlatform, lib }:

rustPlatform.buildRustPackage rec {
  pname = "nispor";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "nispor";
    repo = "nispor";
    rev = "v${version}";
    sha256 = "sha256-zOXYbKb5/Thq3bDbcGTgHKqv2LfE0rGSkQKCplSTJTM=";
  };

  cargoPatches = [ ./add-cargo-lock.patch ];
  cargoSha256 = "sha256-vQiJ+ta+XlOOlnDfhsGK0streqErYlu1rzo6RANTSjg=";

  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/nispor/nispor";
    description = "Unified interface for Linux network state querying";
    license = licenses.asl20;
  };
}
