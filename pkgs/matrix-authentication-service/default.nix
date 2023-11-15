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
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "matrix-org";
    repo = "matrix-authentication-service";
    rev = "refs/tags/v${version}";
    hash = "sha256-RTxQk1Ts/Au8BW9FprAGp4UFNdQzJqW4JuhGztcZbac=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "opa-wasm-0.1.0" = "sha256-kOchQ1pU7qlW5GOSBJc4PC+Xcd/Xh0kWBqkgXjOpqoI=";
    };
  };

  npmDeps = fetchNpmDeps {
    name = "${pname}-${version}-npm-deps";
    src = "${src}/${npmRoot}";
    hash = "sha256-HFqOP4m6+3PAa0C35ybzSnjf2StI9IetCgGNSS5nWFQ=";
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
