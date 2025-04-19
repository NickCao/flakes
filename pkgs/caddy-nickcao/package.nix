{ buildGo124Module, fetchFromGitHub }:

buildGo124Module rec {
  pname = "caddy";
  version = "0-unstable-2025-04-19";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "28a90d5f5ac30bd3f45fd28c676a4e3be9274c2e";
    hash = "sha256-gRHVybZNX+ut59wxA0ukUHdThgmbv3dtaxL/12qXrMo=";
  };

  vendorHash = "sha256-xnz8lAN9ZnrHz4a39cWEq6DKcjSZS9dI4wHktF3z2KE=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
