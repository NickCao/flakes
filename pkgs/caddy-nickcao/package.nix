{ buildGo123Module, fetchFromGitHub }:

buildGo123Module rec {
  pname = "caddy";
  version = "0-unstable-2024-10-27";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "3391918ad5ba95a45737bfa190dcac3c9ccbb462";
    hash = "sha256-74ClKcsfhqkArN25B+QlKr3nEmRDm38sQVICN8u54fI=";
  };

  vendorHash = "sha256-mQSiBIWKJtpHoEhnGRVdYvPOr8fM1xDMn/K0EFFAdm4=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
