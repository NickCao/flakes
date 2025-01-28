{ buildGo123Module, fetchFromGitHub }:

buildGo123Module rec {
  pname = "caddy";
  version = "0-unstable-2025-01-28";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "d38b8d41431d4626b158f1b0ed6cb022c95ce255";
    hash = "sha256-8W6ex0OSvHDzt4h3M5vF3DxOfTVI5rRZGwfQIxOjVBE=";
  };

  vendorHash = "sha256-QgrgK23cBvFHRjRs6wRdILiJvUZ3TQRbaSUg6PvdszU=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
