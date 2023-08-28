{ buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "caddy";
  version = "unstable-2023-08-28";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "d4997f9b8adb32c5e7d0cad70638c1e66e7c6da2";
    hash = "sha256-ih3yuXzd4KHrg9BGM/RG6Iu7NBCsq4qPTf9ZcqrvEFQ=";
  };

  vendorHash = "sha256-azPOec/kNK4y/0UstfaI/yLgZIyQmd1J++C19I/lRys=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
