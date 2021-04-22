{ source, buildGoModule, fetchFromGitHub, lib }:
buildGoModule rec {
  inherit (source) pname version src;
  vendorSha256 = "sha256-Cv8Huor4WdlPvfZkuyim1plM+afqbbig9F8oRQNyfRo=";
  subPackages = [ "." ];
  meta = with lib; {
    homepage = "https://github.com/k0sproject/k0sctl";
    license = licenses.asl20;
  };
}
