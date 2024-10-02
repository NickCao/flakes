{ buildGo123Module, fetchFromGitHub }:

buildGo123Module rec {
  pname = "caddy";
  version = "0-unstable-2024-10-02";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "62e39e55c1cfe3b288ac2f804dd3aab14fb1a9f9";
    hash = "sha256-5wNCB/goCTzVDby33xCfm3htuYjzAiEJisSR1GicW8A=";
  };

  vendorHash = "sha256-6vd4aM9Kc4qH2MJBBh7DRHUnHO06KMrxLJvt7I5KP7A=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
