{ source, buildGoModule, fetchFromGitHub, lib }:
buildGoModule rec {
  inherit (source) pname version src vendorSha256;
  subPackages = [ "cmd/alps" ];
}
