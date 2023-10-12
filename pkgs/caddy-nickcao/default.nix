{ buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "caddy";
  version = "unstable-2023-10-12";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "1e03503b2d1fc75c03d6f57815bf6000fb937a0b";
    hash = "sha256-1dHhh7Op6Dw/Ec6fGxa1OBpZNhJaBuHnQ1emIYd/3rY=";
  };

  vendorHash = "sha256-fQB8SO6d7APPy/MrYOk92AM43JRnmRDfTI0D97Po4y8=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
