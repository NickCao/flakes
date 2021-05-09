{ source, buildGoModule, fetchFromGitHub, lib }:
buildGoModule rec {
  inherit (source) pname version src;
  vendorSha256 = "sha256-8GFZxjkLeTGWxJ3uzaPZaeeJzmmPN9Ao3z8a3JooP0s=";
  subPackages = [ "." ];
  meta = with lib; {
    homepage = "https://github.com/k0sproject/k0sctl";
    license = licenses.asl20;
  };
}
