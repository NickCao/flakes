{ buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "caddy";
  version = "2.6.4";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "452250153f71a9a856052cc47b8655efbc04415a";
    hash = "sha256-Q2NNgzQfS1erF5ZWvha+KuEOo/SI4s2IlxE9YG5xStk=";
  };

  vendorHash = "sha256-oN12XrnZIkF32bB+mrJlRu9xLswJ5l+2YUPNuKaVAJg=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
