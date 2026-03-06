{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "0-unstable-2026-03-06";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "7ba1351d3e7603e9910096adba7c2086e87f2448";
    hash = "sha256-KZ8x5BPPimyMpG6c/RuAGj2UzcyVsRyTSoBeO9e3WIA=";
  };

  vendorHash = "sha256-Q9Ezk0r3W88jVPVXQueIbkyWEwE1evgefvEEZpCeNaY=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
