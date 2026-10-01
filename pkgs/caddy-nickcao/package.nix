{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "0-unstable-2026-10-01";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "a73935dbf19c1b8207fb60183e38bce3afe32120";
    hash = "sha256-XuBsbADqAAppl1omNd3470rPbCqAxB/h04BR38saeeo=";
  };

  vendorHash = "sha256-gO1z0NoIvLjXxg0lr2pqRVgUVADNRGSsQ/pkps8dtYA=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
