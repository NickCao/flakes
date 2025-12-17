{ buildGo125Module, fetchFromGitHub }:

buildGo125Module rec {
  pname = "caddy";
  version = "0-unstable-2025-12-17";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "e506f66920c78c5fbba671f846e9e83905c594b0";
    hash = "sha256-upRBF8IVnvdEnhw7FLjMwWXjYBnCBHXvdga+Hk2fuh8=";
  };

  vendorHash = "sha256-pf5CkUHu4U5dA02CH6nz8O+fcY9aFiaaKNr/MZDI2y4=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
