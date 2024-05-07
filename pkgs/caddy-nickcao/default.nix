{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "0-unstable-2024-05-07";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "e195cdb79edc570fcabab00ce8ab69cd2d1efdbc";
    hash = "sha256-+kTPx/yMyd/AEe965mMdt2m9YyqNVMTne9JOJdUYa00=";
  };

  vendorHash = "sha256-8w8edHmsb3vJ84J83SaPyNZBd1l5Z/UTak23F5GSkRI=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
