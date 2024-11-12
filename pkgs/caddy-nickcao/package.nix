{ buildGo123Module, fetchFromGitHub }:

buildGo123Module rec {
  pname = "caddy";
  version = "0-unstable-2024-11-12";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "0894ae2f6616ff91ded859f791c41619dd7aa845";
    hash = "sha256-Dn9CpAkLVT1FCU/FT7uli2ZzEZXlNbjuEHN9BOU06ks=";
  };

  vendorHash = "sha256-lU5l83aqJ3w8gjMpnC0DCh0492f2rrIr2rLFUukTgx8=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
