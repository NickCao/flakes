{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "2.11.7-unstable-2026-11-05";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "09796284ece6af40b8057888dab2da05170e2172";
    hash = "sha256-VZGdBRdzq5qIo7Ox2ST/jzvvpltSO85nJbzezsWau0g=";
  };

  vendorHash = "sha256-qjLumZHCyoM+lNZtWOTmMlHN5zgB36fv9CkIq3ncMlM=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
