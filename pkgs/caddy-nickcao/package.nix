{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "0-unstable-2024-05-29";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "c14bf74c1667ad16d63e238418aeada9bf65eca8";
    hash = "sha256-bhXjzZtAl6gdYDaR1Ld/faoJ3qhgYVUfGlsVD/1rZN0=";
  };

  vendorHash = "sha256-arjF9cjU+eFFIOElF/6BacGWPHosl+gM+lRMrxSu4VA=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
