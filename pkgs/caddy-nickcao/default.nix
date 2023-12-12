{ buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "caddy";
  version = "unstable-2023-12-12";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "0012e703eaa403af33c3ad8d846db4fb2ba091d9";
    hash = "sha256-K9NW8yCidzULMyCYsmuimiLjT/PMQDzxFdHz9wB2KqQ=";
  };

  vendorHash = "sha256-KlL1WqZSAl1UxL1F1Sory8dETuSUwcHeQgl/eupg05o=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
