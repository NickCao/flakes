{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "0-unstable-2026-02-09";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "40b4f02b3e17c243714749e135407d6fbdcf5579";
    hash = "sha256-Wsmvw44exptMclyWB26OwHbXev3zHBq4KxYyzQp2ubk=";
  };

  vendorHash = "sha256-Aw4qD6Kn/gYuC3Y94OyiWWMerdk8tvtAcm5uqFUMavc=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
