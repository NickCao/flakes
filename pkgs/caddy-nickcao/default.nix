{ buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "caddy";
  version = "2.6.4";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "b34cbebc654255de84c694d7eccbf8c55adcc9a7";
    hash = "sha256-ooo82YXL9llHRV/f1Nn1rI2b75+q9z9lX/RzcPMYDrc=";
  };

  vendorHash = "sha256-70YVXXMVkNf2xwS65ncePueYFrkQNSYY7M9AU7Zs3rY=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
