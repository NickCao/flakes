{ buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "caddy";
  version = "2.7.0-beta.2";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "33a65b3dac03b361099ab0e8fdccfff6537a181e";
    hash = "sha256-VsadybCr8zbuUy58LUrhnw+ssYZnFAXl3cqoJ47mZHY=";
  };

  vendorHash = "sha256-Pg8x2veJsnGlUt18CoMnDjvF56YQ+8X+jeuYcX8kHNo=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
