{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "0-unstable-2026-02-23";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "b3ee8b21519cb7ad67885c728eb602d093ace201";
    hash = "sha256-7mbsDlZzJ72oMQoYFHU0XSdGLMGXtTylOy35ZNXY7zc=";
  };

  vendorHash = "sha256-aPGCTXFCedthFSt5Tzk7MKU49yv7J41g1ezVsMcm9MI=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
