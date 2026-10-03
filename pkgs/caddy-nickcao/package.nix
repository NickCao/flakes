{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "2.11.7-unstable-2026-10-03";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "32fcafa453a216d2b031b918f113f2d98faf3ed8";
    hash = "sha256-FwsoREPr9PHiXe+dxeVgwIs+z5OszfEsvQEf0kcKNbs=";
  };

  vendorHash = "sha256-fbd56GBY93xDWyr9tx4A78QKMTYWlGGLUX82FpKRIRk=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
