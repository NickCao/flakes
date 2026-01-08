{ buildGo125Module, fetchFromGitHub }:

buildGo125Module rec {
  pname = "caddy";
  version = "0-unstable-2026-01-08";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "d99578eac33913e62411e1476c3cc0a00e59b2d3";
    hash = "sha256-M9XM945kifwZYO8iQAXWPu8DnbXmmJf5FoI8GoPTIHI=";
  };

  vendorHash = "sha256-gnUCEXDnB7L1WHTs0SbzoutT/RlmvimCL5X+6L3MWp8=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
