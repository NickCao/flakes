{ buildGo123Module, fetchFromGitHub }:

buildGo123Module rec {
  pname = "caddy";
  version = "0-unstable-2024-12-31";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "ea3b09122a904f6639e6b6769a69e3f01c4ecb70";
    hash = "sha256-ccApC3KAu5DmrWU26RAOsM0xXi1PFgp9sp3lPx1EdY8=";
  };

  vendorHash = "sha256-OMqZk0GtHz4sin/Jtzc580BriLTG29BQzT7B8GJAKdc=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
