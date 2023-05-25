{ buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "caddy";
  version = "2.6.4";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "0501c974052d8bb66b76805ba20ca3ac3a31319b";
    hash = "sha256-VjDwdhrYV7C4meIhMUiqf7eZf4pgr8zRGSkYxD77BR8=";
  };

  vendorHash = "sha256-OeSd8Z+70nqJtEj3pMLuJJ+taop/XV6inkqClTmsfNo=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
