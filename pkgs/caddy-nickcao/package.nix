{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "0-unstable-2024-08-13";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "206d6345d6dd250c9769c0674340ba5e1909211f";
    hash = "sha256-PnO/xtKoKuHLTJc/7XiAF4K1jj8h8zesxLzHQ2qatkg=";
  };

  vendorHash = "sha256-JNOAIchcyyA0BhC3DGjpdd15Kl08C8EnF7ZIC62wycE=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
