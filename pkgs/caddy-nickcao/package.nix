{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "0-unstable-2026-06-10";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "e49b048f1685dc6323a06f0e812c92c879a48c3a";
    hash = "sha256-nTwbb71kVVfC574wUcyb4/g9EZHLbWN0EsMBPk+DLKY=";
  };

  vendorHash = "sha256-lAW7LNoyVY0BB4IxdttpXTV0ZVWqgrFql6u85+9WLYs=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
