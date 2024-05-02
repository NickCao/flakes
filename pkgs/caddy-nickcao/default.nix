{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "0-unstable-2024-05-01";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "0249fb210db1892b7e46812965aaef89bee7ef96";
    hash = "sha256-PhrePUHWltYPCzFo7wW1Y7dUNG8QLcsbZ5+hfliAXBI=";
  };

  vendorHash = "sha256-NevCo/EpYPpHUV+RShJb8WQsWkQudYJkY7glKBKw10w=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
