{ buildGo125Module, fetchFromGitHub }:

buildGo125Module rec {
  pname = "caddy";
  version = "0-unstable-2025-12-04";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "c01342c6c3b6ff8b6cf5c01ec22d96fecd183c17";
    hash = "sha256-JdNte1cNx8AFiI7c/D1RydySu11ltZpykX5VNU77Hgk=";
  };

  vendorHash = "sha256-HL/NCz8ObV114tJI64gNP5bpOPiyfFIq4n+WeJ0Ik4M=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
