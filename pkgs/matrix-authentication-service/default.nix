{ lib
, rustPlatform
, fetchFromGitHub
, fetchNpmDeps
, npmHooks
, nodejs
, pkg-config
, sqlite
, zstd
, stdenv
, darwin
, open-policy-agent
}:

rustPlatform.buildRustPackage rec {
  pname = "matrix-authentication-service";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "matrix-org";
    repo = "matrix-authentication-service";
    rev = "refs/tags/v${version}";
    hash = "sha256-jXC+0nCUpW4ncw5S3/0VE4avez0Oh3r4nqTa3DH/drw=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "opa-wasm-0.1.0" = "sha256-n7+dqWktGPJOguIU3qqcMYLAeaSed01v/cc/dPDKS8g=";
      "ulid-1.0.0" = "sha256-JiyCbFW/XhDxAn9Jee64s4yDq6OP0jgGH8GVDHyuKxc=";
    };
  };

  npmDeps = fetchNpmDeps {
    name = "${pname}-${version}-npm-deps";
    src = "${src}/${npmRoot}";
    hash = "sha256-EDnL/YXfI9DkyDOH237tX9x8rOhBDmiPpG2LHodNq8Q=";
  };

  npmRoot = "frontend";

  nativeBuildInputs = [
    pkg-config
    open-policy-agent
    npmHooks.npmConfigHook
    nodejs
  ];

  buildInputs = [
    sqlite
    zstd
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.CoreFoundation
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  buildNoDefaultFeatures = true;

  buildFeatures = [ "dist" ];

  postPatch = ''
    substituteInPlace crates/config/src/sections/http.rs \
      --replace ./frontend/dist/    "$out/share/$pname/assets/"
    substituteInPlace crates/config/src/sections/templates.rs \
      --replace ./share/templates/    "$out/share/$pname/templates/" \
      --replace ./share/manifest.json "$out/share/$pname/assets/manifest.json"
    substituteInPlace crates/config/src/sections/policy.rs \
      --replace ./share/policy.wasm "$out/share/$pname/policy.wasm"
  '';

  preBuild = ''
    make -C policies
    (cd "$npmRoot" && npm run build)
  '';

  postInstall = ''
    install -Dm444 -t "$out/share/$pname"        "policies/policy.wasm"
    install -Dm444 -t "$out/share/$pname/assets" "$npmRoot/dist/"*
    cp -r templates   "$out/share/$pname/templates"
  '';

  meta = with lib; {
    description = "OAuth2.0 + OpenID Provider for Matrix Homeservers";
    homepage = "https://github.com/matrix-org/matrix-authentication-service";
    changelog = "https://github.com/matrix-org/matrix-authentication-service/releases/tag/v${version}";
    license = licenses.asl20;
    maintainers = with maintainers; [ nickcao ];
    mainProgram = "matrix-authentication-service";
  };
}
