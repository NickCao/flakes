{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "2.11.7-unstable-2026-10-12";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "547b25f7acbf877ea4f00e062274c465cd3dc8e0";
    hash = "sha256-kxILmz0i2Y28NT/BckJA+yaipfagMWIP2bzbdEQqyKw=";
  };

  vendorHash = "sha256-JsE24egPnnQxLBoZ8jic7Rn9KAx+geVpONI/vXJLDRs=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
