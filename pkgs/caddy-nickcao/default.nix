{ buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "caddy";
  version = "unstable-2023-08-07";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "8352ba4540efee4a086628ed8863b8c43e514b8f";
    hash = "sha256-SQWNG4P8yx4jvTCVOEpGIH2g3C6uUQjbyy/lEzC3Hl8=";
  };

  vendorHash = "sha256-UPRJVUUKn9dbtLF3sq0XH445lHCEjRneVWqoHJTfxwY=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
