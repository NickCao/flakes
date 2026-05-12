{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "caddy";
  version = "0-unstable-2026-05-12";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "caddy";
    rev = "9c3c685bb2303412d1d10a98c38838a37ceb835f";
    hash = "sha256-wvhVmi2Qoq0iLo6GOxSf6pdqiAtI6rfCZEec3y/NoJs=";
  };

  vendorHash = "sha256-wuPEIWmtX0udtiNLKF2DIonmM7mVIfe9vf/j0we5LFE=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
