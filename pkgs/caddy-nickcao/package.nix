{ buildGo125Module, fetchFromGitHub }:

buildGo125Module rec {
  pname = "caddy";
  version = "0-unstable-2025-08-22";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "7ffa1ddc3830c81e03f499dda101712dbc0cf72e";
    hash = "sha256-8yTxuYUTLPbBbSaymnfsdwwngQLgyhR9Bqqp1Di+jUI=";
  };

  vendorHash = "sha256-jw4vRTd39n3Qnahb1UVy+RhrFZplzOXaOEClx67FRRw=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
