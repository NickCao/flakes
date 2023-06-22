{ buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "caddy";
  version = "2.7.0-beta.2";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "a7512db8be3ad5c3fc7a7d30e77f35f810fc44ce";
    hash = "sha256-ROQcCaTNsV6XQq59kZp/Fb9a84xtF3O3Sx24WbXJNos=";
  };

  vendorHash = "sha256-12JtK1hLkEwnTzS8hQdYN8G6eXZbsrVsyQBaedA3P4c=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
