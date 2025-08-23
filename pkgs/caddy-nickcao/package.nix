{ buildGo125Module, fetchFromGitHub }:

buildGo125Module rec {
  pname = "caddy";
  version = "0-unstable-2025-08-23";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "11686f4be1b28dae88ef398c86e7b36616d4560d";
    hash = "sha256-t3MZxTx767ZgNC4Z1V+LjLmoeZfJGDmwh5wdvYnmnvg=";
  };

  vendorHash = "sha256-jw4vRTd39n3Qnahb1UVy+RhrFZplzOXaOEClx67FRRw=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
