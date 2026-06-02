{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "0-unstable-2026-06-03";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "85dddc0fe6a219c64695fc58027f2b1badb0ad91";
    hash = "sha256-p++tqd75hL+GZv61upr4s08eoSEON6BJQJFYol3Z2KY=";
  };

  vendorHash = "sha256-lAW7LNoyVY0BB4IxdttpXTV0ZVWqgrFql6u85+9WLYs=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
